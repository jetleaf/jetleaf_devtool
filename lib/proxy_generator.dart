// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

// ignore_for_file: deprecated_member_use, depend_on_referenced_packages

import 'dart:async';

import 'package:build/build.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
// nullability suffix handled via DartType.getDisplayString(withNullability: true)
import 'package:jetleaf_core/annotation.dart';

final Uri _INTERCEPT_URI = Uri.parse("package:jetleaf_core/intercept.dart");
final Uri _LANG_URI = Uri.parse('package:jetleaf_lang/lang.dart');

/// {@template proxy_generator}
/// # Proxy Generator
///
/// Generates runtime proxy subclasses for all classes annotated with JetLeaf
/// stereotypes such as:
/// - `@Service`
/// - `@Component`
/// - `@Configuration`
/// - `@AutoConfiguration`
/// - `@Repository`
/// - `@Controller`
///
/// The proxies produced by this generator form the foundation of JetLeaf’s
/// **AOP interception system**, enabling runtime interception, tracing,
/// and behavior modification on user-defined services.
///
/// ---
///
/// ## Overview
/// The [ProxyGenerator] operates as a `build_runner` code generator that:
/// 1. Scans Dart libraries for eligible annotated classes.
/// 2. Verifies extendability (non-`final`, non-private).
/// 3. Collects all import dependencies (both direct and transitive) for
///    correct type alias resolution.
/// 4. Emits a new class prefixed with `$$`, e.g.:
///
/// ```dart
/// @Service()
/// class UserService { ... }
///
/// // Auto-generated:
/// final class $$UserService with Interceptable implements UserService, ClassGettable<UserService> {
///   final UserService delegate;
///
///   $$UserService(this.delegate);
///
///   @override
///   Future<User> findUser(String id) async => when<User>(
///     () async => delegate.findUser(id),
///     'findUser',
///     MethodArguments(positionalArgs: [id]),
///   );
/// }
/// ```
///
/// Each generated proxy class:
/// - Implements both the target class and `ClassGettable<T>`.
/// - Mixes in `Interceptable` to delegate method calls through
///   `MethodInterceptorDispatcher`.
/// - Forwards properties and methods to the delegate object.
/// - Wraps interceptable methods with `when()` for interception.
///
/// ---
///
/// ## Generation Workflow
///
/// 1. **Annotation Scan**
///    - Filters classes with JetLeaf stereotype annotations.
///    - Ensures they are not `final` or from an external package.
///
/// 2. **Import and Alias Construction**
///    - Captures the original source file’s imports.
///    - Adds imports for JetLeaf core libraries:
///      - `package:jetleaf_core/intercept.dart`
///      - `package:jetleaf_lang/lang.dart`
///    - Generates URI aliases to avoid import name collisions.
///
/// 3. **Proxy Emission**
///    - Emits proxy class definitions with:
///      - Correct import aliasing
///      - Generated headers
///      - Wrapped delegates
///      - Method overrides supporting interception
///
/// 4. **Method Generation**
///    - Each method override uses:
///      - `this.when<T>(...)` if return type is async/interceptable
///      - Direct `delegate.method(...)` otherwise
///
/// 5. **Property Forwarding**
///    - Forwards getters/setters and public fields directly to delegate.
///
/// ---
///
/// ## Design Notes
///
/// ### 1. Interceptable Return Types
/// The generator detects methods returning `Future` or `FutureOr` and wraps
/// them in `when<T>()`, allowing asynchronous interception chains.
///
/// ```dart
/// Future<User> getUser(String id) async => when<User>(
///   () async => delegate.getUser(id),
///   'getUser',
///   MethodArguments(positionalArgs: [id]),
/// );
/// ```
///
/// ### 2. Aliased Imports
/// Every referenced type (return types, parameter types, supertypes)
/// is imported via URI aliases to prevent symbol conflicts and to ensure
/// generated proxies are always valid even across modular package boundaries.
///
/// ```dart
/// import 'package:my_app/src/user_service.dart' as _i1;
/// import 'package:jetleaf_core/intercept.dart' as _i2;
/// ```
///
/// ### 3. Safety and Compatibility
/// - Skips `dart:` internal URIs automatically (`dart:_internal`, etc.)
/// - Skips final or external classes
/// - Emits proxies into `_jetleaf` or configured build target directory
///
/// ---
///
/// ## Internal API
///
/// ### `_hasStereotypeAnnotation`
/// Detects if a class has any of the known JetLeaf stereotypes, including
/// meta-annotations (e.g., custom annotations that themselves are annotated
/// with `@Service`).
///
/// ### `_generateProxyForClass`
/// The core emission logic that:
/// - Writes imports
/// - Declares proxy fields and constructors
/// - Generates property accessors and method overrides
/// - Implements `toClass()` from `ClassGettable`
///
/// ### `_emitMethodOverride`
/// Builds method overrides that wrap async methods in interceptable calls.
/// Handles operator forwarding, parameter reconstruction, and argument
/// serialization into `MethodArguments`.
///
/// ---
///
/// ## Generated Output Example
///
/// ```dart
/// final class $$OrderService with Interceptable implements OrderService, ClassGettable<OrderService> {
///   final OrderService delegate;
///
///   $$OrderService(this.delegate);
///
///   @override
///   Future<Order> findOrder(String id) async {
///     return this.when<Order>(
///       () async => delegate.findOrder(id),
///       'findOrder',
///       MethodArguments(positionalArgs: [id]),
///     );
///   }
///
///   @override
///   Class<OrderService> toClass() => Class<OrderService>(null, delegate.getClass().getPackage()?.getName());
/// }
/// ```
///
/// ---
///
/// ## Integration Points
///
/// | System | Role |
/// |---------|------|
/// | **Interceptable** | Provides `when()` logic and dispatcher bridge |
/// | **ClassGettable** | Enables runtime type reflection support |
/// | **ProxyCommandRunner** | CLI entrypoint that triggers `ProxyGenerator` via `build_runner` |
/// | **MethodInterceptorDispatcher** | Executes registered interceptors per method |
///
/// ---
///
/// ## Developer Notes
/// - Proxies are generated at compile-time via `build_runner`.
/// - Proxy generation should be run prior to hot reload or packaging.
/// - This generator does **not** modify the original source files.
///
/// ---
///
/// ## Related
/// - [Interceptable] — mixin for runtime interception
/// - [ProxyCommandRunner] — CLI command invoking this generator
/// - [MethodInterceptorDispatcher] — dispatcher managing intercept chains
/// - [ClassGettable] — runtime type metadata provider
///
/// {@endtemplate}
class ProxyGenerator extends Generator {
  /// {@macro proxy_generator}
  ProxyGenerator();

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final annotated = library.classes.where((el) => _hasStereotypeAnnotation(el) && (el.isExtendableOutside || el.isImplementableOutside || el.isMixableOutside) && !_hasInterceptableMixinOrSuper(el)).toList();
    if (annotated.isEmpty) return '';

    // read source to capture imports verbatim
    final imports = library.element.firstFragment.importedLibraries.map((i) => i.uri.toString()).toList();
    imports.addAll([
      'package:jetleaf_core/intercept.dart',
      'package:jetleaf_lang/lang.dart'
    ]);

    // collect all URIs we will need to import with aliases:
    // - the original library (we'll import by URI)
    // - every library that owns a referenced type (param types, return types, supertypes)
    final neededUris = <Uri>{library.element.uri};

    // accumulate types while scanning classes and supertypes
    for (final cls in annotated) {
      neededUris.addAll(_collectUrisForClass(cls));
    }

    // also ensure we include jetleaf intercept package
    final interceptUri = Uri.parse('package:jetleaf_core/intercept.dart');
    neededUris.add(interceptUri);
    neededUris.add(_INTERCEPT_URI);
    neededUris.add(_LANG_URI);
  
    // build alias map
    final aliasMap = <Uri, String>{};
    for (final uri in neededUris) {
      aliasMap[uri] = _aliasForUri(uri);
    }

    // Begin building output
    final buffer = StringBuffer();
    _writeHeader(buffer, library.element.uri.toString());

    // print original source imports first to preserve local context
    _writeImports(buffer, imports, aliased: false);

    // Add aliased imports for every neededUri (skip the current library import line since it's already present)
    for (final uri in neededUris) {
      final uriStr = uri.toString();
      // skip internal dart:_ URIs — they are internal to the SDK and cannot be imported by user code
      if (_isInternalSdkUri(uri)) {
        // ensure we still have an alias entry to avoid crashes, but do NOT emit an import
        continue;
      }
      final alias = aliasMap[uri]!;
      // avoid re-importing the current library if it's already in the file's original imports
      buffer.writeln("import '$uriStr' as $alias;");
    }

    buffer.writeln();

    // For each annotated class, generate proxy
    for (final cls in annotated) {
      _generateProxyForClass(buffer, cls, aliasMap, buildStep);
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// A registry of all recognized *stereotype annotations* used by JetLeaf.
  ///
  /// Stereotypes define semantic roles for annotated classes—such as
  /// [Service], [Controller], or [Repository] —that the framework uses
  /// during code generation and dependency injection.
  ///
  /// Each stereotype corresponds to a specific JetLeaf meta-annotation type,
  /// and this list allows the annotation scanner to detect whether a class
  /// participates in the JetLeaf component model.
  ///
  /// The list is transformed into a collection of [TypeChecker]s so that
  /// the analyzer can inspect Dart elements (via `analyzer` package)
  /// for these annotations.
  ///
  /// ### Example
  /// ```dart
  /// @Service()
  /// class UserService {}
  ///
  /// final isService = _hasStereotypeAnnotation(userServiceElement);
  /// // → true
  /// ```
  ///
  /// ### Notes
  /// - All stereotype classes must be resolvable at *build-time*.
  /// - When adding a new stereotype annotation (e.g. `@Listener`),
  ///   register it here to ensure build-time proxy generation recognizes it.
  final _stereotypes = <Type>{
    Component,
    Service,
    Configuration,
    AutoConfiguration,
    ReflectableAnnotation,
  }.map((t) => TypeChecker.typeNamed(t)).toList();

  /// Determines whether the given [element] has any annotation that matches
  /// one of the registered stereotype [TypeChecker]s.
  ///
  /// A *stereotype annotation* represents a meta-level marker (e.g. `@Service`,
  /// `@Controller`, etc.) that indicates a special framework behavior.
  ///
  /// This method performs two levels of checking:
  /// 1. **Direct annotation check** – looks for annotations directly applied
  ///    on the class (using both `hasAnnotationOf` and `hasAnnotationOfExact`).
  /// 2. **Meta-annotation fallback** – for rare cases where the class’s own
  ///    annotations themselves are annotated with a stereotype (nested meta-annotations).
  ///
  /// Example:
  /// ```dart
  /// @Service()
  /// class UserService {}
  ///
  /// final hasStereotype = _hasStereotypeAnnotation(userServiceElement);
  /// // → true
  /// ```
  ///
  /// @param element The [ClassElement] to inspect.
  /// @return `true` if the element or any of its annotations match a known stereotype.
  bool _hasStereotypeAnnotation(ClassElement element) {
    for (final checker in _stereotypes) {
      if (checker.hasAnnotationOf(element) || checker.hasAnnotationOfExact(element)) {
        return true;
      }
    }

    // fallback: also check meta-annotations on annotations (rare)
    for (final meta in element.metadata.annotations) {
      final val = meta.computeConstantValue();
      if (val == null) continue;
      final annType = val.type;
      if (annType == null) continue;
      for (final checker in _stereotypes) {
        if (checker.isAssignableFromType(annType)) return true;
      }
    }

    return false;
  }

  /// Generates a Dart proxy class for a given [ClassElement].
  ///
  /// This function emits a full `final class` definition that wraps the
  /// specified source class (`cls`) and delegates all property and method calls
  /// to its underlying `delegate` instance, while integrating with JetLeaf’s
  /// runtime interception layer.
  ///
  /// ### Overview
  /// Each generated proxy class:
  /// - Extends JetLeaf’s [`Interceptable`] mixin, enabling runtime interception
  ///   of method invocations.
  /// - Implements [`ClassGettable`] to expose type metadata through
  ///   `toClass()`.
  /// - Mirrors all non-static public members (methods, fields, accessors) of
  ///   the source class and its supertypes.
  ///
  /// ### Example
  /// For a source class:
  /// ```dart
  /// @Service()
  /// class UserService {
  ///   String greet(String name) => 'Hello $name';
  /// }
  /// ```
  ///
  /// This generator produces:
  /// ```dart
  /// final class $$UserService with Interceptable implements
  ///   lib_core.UserService, lang.ClassGettable<lib_core.UserService> {
  ///
  ///   final lib_core.UserService delegate;
  ///
  ///   $$UserService(this.delegate);
  ///
  ///   @override
  ///   String greet(String name) => delegate.greet(name);
  ///
  ///   @override
  ///   Class<lib_core.UserService> toClass()
  ///       => lang.Class<lib_core.UserService>(null, delegate.getClass().getPackage()?.getName());
  /// }
  /// ```
  ///
  /// ### Parameters
  /// - [buffer] — the output buffer receiving generated Dart source.
  /// - [cls] — the [ClassElement] analyzed from the input library via
  ///   `analyzer`.
  /// - [aliasMap] — mapping from `Uri` → import alias used to ensure
  ///   disambiguation between source libraries.
  /// - [buildStep] — the current build phase context from `build_runner`.
  ///
  /// ### References
  /// - [`ClassElement`](https://pub.dev/documentation/analyzer/latest/dart_element_element/ClassElement-class.html)
  /// - [`BuildStep`](https://pub.dev/documentation/build/latest/build/BuildStep-class.html)
  /// - JetLeaf Interception API: `package:jetleaf_core/intercept.dart`
  /// - JetLeaf Language Model: `package:jetleaf_lang/lang.dart`
  ///
  /// ### Notes
  /// - Private or static members are excluded.
  /// - Methods returning `Future` or `FutureOr` are automatically wrapped
  ///   with asynchronous interception hooks.
  /// - Equality (`operator ==`) is implemented to delegate directly to
  ///   the proxied instance.
  ///
  /// This function is the heart of the proxy generation pipeline, translating
  /// analyzer metadata into JetLeaf runtime-compatible Dart code.
  void _generateProxyForClass(StringBuffer buffer, ClassElement cls, Map<Uri, String> aliasMap, BuildStep buildStep) {
    final className = cls.name;
    final proxyName = '${Constant.PROXY_IDENTIFIER}$className';

    // Compose implements list using aliased type identifiers
    final implementsParts = <String>[];

    // Primary: implement the original (aliased)
    final classLibUri = cls.library.uri;
    final classAlias = aliasMap[classLibUri]!;
    final aliasedClass = '$classAlias.$className';
    final packageName = buildStep.inputId.package;
    final qualifiedName = "${classLibUri.toString()}.$className";

    // Build a substitution map for type parameters declared on supertypes
    // Example: class EmptyRepository extends CrudRepository<Empty, int>
    // The CrudRepository type parameters (T, ID) should map to Empty and int
    final Map<TypeParameterElement, DartType> typeArgSubst = {};
    for (final st in cls.allSupertypes) {
      final params = st.element.typeParameters;
      final args = st.typeArguments;
      final len = params.length < args.length ? params.length : args.length;
      for (var i = 0; i < len; i++) {
        try {
          typeArgSubst[params[i]] = args[i];
        } catch (_) {
          // ignore any unexpected mismatch
        }
      }
    }

    // ---- Interface composition ----------------------------------------------
    // Construct aliased identifiers for interface implementation.
    // If the class itself declares type parameters, emit them on the proxy
    final classIsGeneric = cls.typeParameters.isNotEmpty;
    String classTypeParamsDecl = '';
    String classTypeParamsUse = '';
    if (classIsGeneric) {
      final decls = cls.typeParameters.map((p) {
        final bound = p.bound != null ? ' extends ${_formatType(p.bound!, aliasMap, null)}' : '';
        return '${p.name}$bound';
      }).join(', ');
      classTypeParamsDecl = '<$decls>';
      classTypeParamsUse = '<${cls.typeParameters.map((p) => p.name).join(', ')}>';
    }

    final aliasedClassWithParams = classIsGeneric ? '$aliasedClass$classTypeParamsUse' : aliasedClass;

    implementsParts.add(aliasedClassWithParams);
  implementsParts.add('${aliasMap[_LANG_URI]!}.ClassGettable<$aliasedClassWithParams>');

  final jetleafLangAlias = aliasMap[_LANG_URI];
  final classGettableReturn = jetleafLangAlias != null ? '$jetleafLangAlias.Class<$aliasedClassWithParams>(null, "$packageName")' : 'Class<$aliasedClassWithParams>(null, "$packageName")';

    // ---- Header documentation and class declaration --------------------------
    buffer.writeln('/// {@template ${proxyName.toLowerCase()}}');
    buffer.writeln('/// Proxy implementation for [`$aliasedClass`].');
    buffer.writeln('///');
    buffer.writeln('/// This class is automatically generated by the JetLeaf proxy generator.');
    buffer.writeln('/// It wraps an instance of `$aliasedClass` (`delegate`) to provide interception,');
    buffer.writeln('/// lifecycle management, and runtime integration with JetLeaf\'s `Interceptable` system.');
    buffer.writeln('///');
    buffer.writeln('/// All method calls on this proxy are forwarded to the underlying delegate,');
    buffer.writeln('/// with applicable methods being intercepted through the `when` mechanism.');
    buffer.writeln('///');
    if (cls.documentationComment != null) {
      buffer.writeln(cls.documentationComment);
    }
    buffer.writeln('/// See also:');
    buffer.writeln('/// - [${aliasMap[_INTERCEPT_URI]!}.Interceptable]');
    buffer.writeln('/// - [${aliasMap[_LANG_URI]!}.ClassGettable]');
    buffer.writeln('/// - [$aliasedClass]');
    buffer.writeln('///');
    buffer.writeln('/// {@endtemplate}');
  buffer.writeln('final class $proxyName$classTypeParamsDecl with ${aliasMap[_INTERCEPT_URI]!}.Interceptable implements ${implementsParts.join(', ')} {');

    // ---- Delegate field ------------------------------------------------------
    buffer.writeln('  /// Underlying instance of the original class being proxied.');
    buffer.writeln('  ///');
    buffer.writeln('  /// This is the actual [$aliasedClass] instance that the proxy wraps.');
    buffer.writeln('  /// All property and method calls are forwarded to this delegate unless');
    buffer.writeln('  /// explicitly intercepted by the JetLeaf runtime through the');
    buffer.writeln('  /// [${aliasMap[_INTERCEPT_URI]!}.Interceptable] mechanism.');
    buffer.writeln('  ///');
    buffer.writeln('  /// The delegate remains the single source of truth for all state and logic,');
    buffer.writeln('  /// ensuring that the proxy layer adds interception and lifecycle management');
    buffer.writeln('  /// without modifying the behavior of the original class.');
  buffer.writeln('  final $aliasedClassWithParams delegate;');
    buffer.writeln();
    buffer.writeln('  /// Holds the JetLeaf runtime representation of the proxied class.');
    buffer.writeln('  ///');
    buffer.writeln('  /// This field stores a reference to the [${aliasMap[_LANG_URI]!}.Class] metadata object that');
    buffer.writeln('  /// describes the proxied type ($aliasedClass) within the JetLeaf runtime.');
    buffer.writeln('  /// It is initialized automatically when the proxy is registered or resolved');
    buffer.writeln('  /// through dependency injection.');
    buffer.writeln('  ///');
    buffer.writeln('  /// The [${aliasMap[_LANG_URI]!}.Class] object provides reflective access to the class’s');
    buffer.writeln('  /// methods, fields, annotations, and generic type information, and is used');
    buffer.writeln('  /// internally by the JetLeaf runtime for validation, interception,');
    buffer.writeln('  /// and lifecycle management.');
    buffer.writeln('  ///');
    buffer.writeln('  /// This field is marked as `late` because it is set after proxy');
    buffer.writeln('  /// construction but before any intercepted method is invoked.');
  buffer.writeln('  late $jetleafLangAlias.Class<$aliasedClassWithParams> _class;');
    buffer.writeln();
    buffer.writeln('  /// Creates a new proxy wrapping the provided [delegate].');
    buffer.writeln('  ///');
    buffer.writeln('  /// {@macro ${proxyName.toLowerCase()}}');
    buffer.writeln('  $proxyName(this.delegate)');
    buffer.writeln('    : _class = $classGettableReturn;');
    buffer.writeln();
    buffer.writeln('  /// Returns the JetLeaf runtime [$jetleafLangAlias.Class] metadata object');
    buffer.writeln('  /// representing the underlying [$aliasedClass] type.');
    buffer.writeln('  ///');
    buffer.writeln('  /// This method can be used to resolve the fully-qualified JetLeaf');
    buffer.writeln('  /// class definition for this proxy, allowing reflective lookups,');
    buffer.writeln('  /// annotation access, and runtime metadata introspection.');
    buffer.writeln('  ///');
    buffer.writeln('  /// Example qualified name:');
    buffer.writeln('  /// ```dart');
    buffer.writeln('  /// $qualifiedName');
    buffer.writeln('  /// ```');
    buffer.writeln('  ///');
  buffer.writeln('  static $jetleafLangAlias.Class<$aliasedClassWithParams> ${Constant.STATIC_REAL_CLASS_METHOD_NAME}() => $jetleafLangAlias.Class.fromQualifiedName("$qualifiedName");');
    buffer.writeln();

    // ---- Member collection ---------------------------------------------------
    // gather all required members: methods/getters/setters/fields from class and all supertypes/interfaces
    final requiredMembers = <String, ExecutableElement>{};
    final propertyMembers = <String, PropertyIndication>{}; // for getters/setters/fields

    void collectFromInterface(InterfaceType it) {
      final el = it.element;
      for (final m in el.methods) {
        if (m.isStatic || m.isPrivate) continue;

        final key = m.name ?? m.displayName;
        // prefer concrete implementations declared in the concrete class (we'll overlay later)
        requiredMembers.putIfAbsent(key, () => m);
      }

      for (final f in el.fields) {
        if (f.isStatic || f.isPrivate) continue;
        final key = f.name ?? f.displayName;
        propertyMembers.putIfAbsent(key, () => PropertyIndication(key, f.type, f));
      }

      for (final acc in el.getters) {
        if (acc.isStatic || acc.isPrivate) continue;
        final key = acc.name ?? acc.displayName;
        propertyMembers.putIfAbsent(key, () => PropertyIndication(key, acc.returnType, acc));
      }

      for (final acc in el.setters) {
        if (acc.isStatic || acc.isPrivate) continue;
        final key = acc.name ?? acc.displayName;
        propertyMembers.putIfAbsent(key, () => PropertyIndication(key, acc.returnType, acc));
      }
    }

    // collect from all supertypes (interfaces, mixins, superclass chain)
    for (final it in cls.allSupertypes) {
      collectFromInterface(it);
    }

    // collect from the class itself (declared methods/fields). These should override inherited ones.
    for (final m in cls.methods) {
      if (m.isStatic || m.isPrivate) continue;
      final key = m.name ?? m.displayName;
      requiredMembers[key] = m; // override inherited
    }

    for (final f in cls.fields) {
      if (f.isStatic || f.isPrivate) continue;
      final key = f.name ?? f.displayName;
      propertyMembers[key] = PropertyIndication(key, f.type, f);
    }
    
    for (final acc in cls.getters) {
      if (acc.isStatic || acc.isPrivate) continue;
      final key = acc.name ?? acc.displayName;
      propertyMembers.putIfAbsent(key, () => PropertyIndication(key, acc.returnType, acc));
    }

    for (final acc in cls.setters) {
      if (acc.isStatic || acc.isPrivate) continue;
      final key = acc.name ?? acc.displayName;
      propertyMembers.putIfAbsent(key, () => PropertyIndication(key, acc.returnType, acc));
    }

    // Now produce code for properties (fields/getters/setters)
    for (final pEntry in propertyMembers.entries) {
      final prop = pEntry.value;
      final typeStr = _formatType(prop.type, aliasMap, typeArgSubst);
      // generate getter if available (or field read)
      buffer.writeln('  @override');
      buffer.writeln('  $typeStr get ${prop.name} => delegate.${prop.name};');
      // setter if setter expected (we'll always generate a setter if the property isn't final)
      // We can't tell finalness easily from a getter-only accessor; check element if available
      // final isMutable = prop.element is FieldElement ? !(prop.element as FieldElement).isFinal : true;
      // if (isMutable) {
      //   buffer.writeln();
      //   buffer.writeln('  @override');
      //   buffer.writeln('  set ${prop.name}($typeStr value) { delegate.${prop.name} = value; }');
      // }
      buffer.writeln();
    }

    // Methods: deduplicate keys and produce overrides
    final emitted = <String>{};
    for (final entry in requiredMembers.entries) {
      final elem = entry.value;
      final key = entry.key;
      if (emitted.contains(key)) continue;
      emitted.add(key);

      if (key == '==') {
        // Emit operator == with correct signature
        buffer.writeln('  @override');
        buffer.writeln('  bool operator ==(Object other) {');
        buffer.writeln('    if (other is $proxyName) return delegate == other.delegate;');
        buffer.writeln('    return delegate == other;');

        buffer.writeln('  }');
        buffer.writeln();
        continue; // don't run the usual _emitMethodOverride
      }

      if (key == 'toString') {
        // Emit enhanced toString for better debugging
        buffer.writeln('  @override');
        buffer.writeln('  String toString() => "${proxyName.replaceAll(r'$', r'\$')}(\${delegate.toString()})";');
        buffer.writeln();
        continue;
      }

      if (elem is MethodElement) {
        _emitMethodOverride(buffer, elem, aliasMap, '_class', typeArgSubst);
      }
    }

    // toClass implementation (ClassGettable)
    buffer.writeln('  @override');
  buffer.writeln('  $jetleafLangAlias.Class<$aliasedClassWithParams> toClass() => _class;');

    buffer.writeln('}'); // end class
  }

  /// Emits an override implementation for a given [method] from the target class.
  ///
  /// This function writes the source code of an overridden method into the
  /// [buffer]. It determines whether the method is subject to interception,
  /// and if so, wraps its invocation with JetLeaf’s `Interceptable.when`
  /// mechanism. Otherwise, it emits a direct delegate call.
  ///
  /// ### Responsibilities
  /// - Replicates the full method signature (return type, generics, and parameters).
  /// - Injects interception logic for methods that return asynchronous or
  ///   interceptable types.
  /// - Preserves null safety and async semantics (`async` modifier inferred from
  ///   return type).
  /// - Passes detailed argument metadata (`positionalArgs`, `namedArgs`) to the
  ///   interception layer.
  ///
  /// ### Example (Generated Output)
  /// ```dart
  /// @override
  /// Future<User> findUser(String id) async {
  ///   return this.when<User>(
  ///     () async => delegate.findUser(id),
  ///     delegate,
  ///     'findUser',
  ///     intercept.MethodArguments(
  ///       positionalArgs: [id],
  ///       namedArgs: {},
  ///     ),
  ///   );
  /// }
  /// ```
  ///
  /// ### Parameters
  /// - [buffer] – Output sink for the generated Dart code.
  /// - [method] – The [MethodElement] representing the method being proxied,
  ///   retrieved from the `analyzer` API.
  /// - [aliasMap] – A map of library URIs to import aliases used to produce
  ///   properly-qualified type names (e.g. `core.User`).
  ///
  /// ### Behavior
  /// - If the return type is `Future<T>` or `FutureOr<T>`, the emitted method
  ///   includes an `async` modifier.
  /// - If the return type is interceptable (e.g., `Future<T>` subject to
  ///   JetLeaf’s runtime interception), it is wrapped in a call to
  ///   `Interceptable.when<T>()`.
  /// - Otherwise, it directly delegates the call:
  ///   ```dart
  ///   return delegate.methodName(args);
  ///   ```
  ///
  /// ### References
  /// - [`MethodElement`](https://pub.dev/documentation/analyzer/latest/dart_element_element/MethodElement-class.html)
  /// - [`Interceptable`](https://pub.dev/documentation/jetleaf_core/latest/intercept/Interceptable-class.html)
  /// - [`MethodArguments`](https://pub.dev/documentation/jetleaf_core/latest/intercept/MethodArguments-class.html)
  ///
  /// ### See Also
  /// - `_buildParameterSignatureWithTypes` for parameter code synthesis.
  /// - `_isInterceptableReturnType` for determining interceptability.
  /// - `_extractTieType` for resolving the inner type of a generic `Future<T>`.
  ///
  /// This function directly contributes to JetLeaf’s dynamic AOP-style method
  /// interception at runtime.
  void _emitMethodOverride(StringBuffer buffer, MethodElement method, Map<Uri, String> aliasMap, String classType, [Map<TypeParameterElement, DartType>? typeSubst]) {
    final methodName = method.name;
    final returnType = _formatType(method.returnType, aliasMap, typeSubst);
    final paramsSig = _buildParameterSignatureWithTypes(method, aliasMap, typeSubst);
    final invocationArgs = _buildInvocationArgs(method);
    final positionalArgs = _positionalArgsList(method);
    final namedArgsMap = _namedArgsMap(method);

    final isInterceptable = _isInterceptableReturnType(method.returnType);
    // determine whether to mark async on signature: use return-type inference (Future/FutureOr)
    final isAsync = _isAsyncLike(method.returnType);

    // Method-level type parameters (e.g. <S, U extends X>)
    String methodTypeParamsDecl = '';
    String methodTypeParamsUse = '';
    if (method.typeParameters.isNotEmpty) {
      final decls = method.typeParameters.map((p) {
        final bound = p.bound != null ? ' extends ${_formatType(p.bound!, aliasMap, typeSubst)}' : '';
        return '${p.name}$bound';
      }).join(', ');
      methodTypeParamsDecl = '<$decls>';
      methodTypeParamsUse = '<${method.typeParameters.map((p) => p.name).join(', ')}>';
    }

    // --- Method header -------------------------------------------------------
    buffer.writeln('  @override');
  buffer.writeln('  $returnType $methodName$methodTypeParamsDecl($paramsSig)${isAsync || isInterceptable ? " async" : ""} {');

    // --- Interception-aware emission ----------------------------------------
    if (isInterceptable) {
      // tie type (inner generic for Future<T>)
      final tieType = _extractTieType(method.returnType, aliasMap, typeSubst);
  buffer.writeln('    return this.when<$tieType>(');
  buffer.writeln('      () async => delegate.$methodName$methodTypeParamsUse($invocationArgs),');
      buffer.writeln("      delegate,");
      buffer.writeln("      '$methodName',");
      buffer.writeln('      ${aliasMap[_INTERCEPT_URI]!}.MethodArguments(');
      buffer.writeln('        positionalArgs: [$positionalArgs],');
      buffer.writeln('        namedArgs: {$namedArgsMap},');
      buffer.writeln('      ),');
      buffer.writeln('      $classType,');
      buffer.writeln('    );');
    } else {
      buffer.writeln('    return delegate.$methodName$methodTypeParamsUse($invocationArgs);');
    }

    // --- Method footer -------------------------------------------------------
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// Builds the complete Dart parameter signature string for a given [method].
  ///
  /// This function synthesizes a parameter list (including types, names,
  /// and `required` keywords) that mirrors the original method’s declaration.
  /// It correctly handles **required positional**, **optional positional**, and
  /// **named parameters**, preserving their declaration order and optionality.
  ///
  /// The resulting string can be safely inserted into generated code such as:
  /// ```dart
  /// void example(${_buildParameterSignatureWithTypes(method, aliasMap)}) { ... }
  /// ```
  ///
  /// ### Example
  /// For a method declaration like:
  /// ```dart
  /// Future<void> fetchUser(String id, {int retries = 3, required bool log});
  /// ```
  /// this function will return:
  /// ```
  /// String id, {int retries, required bool log}
  /// ```
  ///
  /// ### Parameter Categories
  /// - **Required positional:** `[String id, int age]`
  /// - **Optional positional:** `[{String? label}]`
  /// - **Named parameters:** `{required bool active, int retries}`
  ///
  /// ### Type Aliasing
  /// Types are formatted using [_formatType], which leverages [aliasMap]
  /// to resolve prefixed imports and avoid ambiguous references in generated code.
  ///
  /// ### Parameters
  /// - [method] – The [MethodElement] being analyzed.
  /// - [aliasMap] – Maps each library’s [Uri] to its assigned import alias.
  ///
  /// ### Returns
  /// A syntactically valid Dart parameter signature (excluding parentheses).
  ///
  /// ### See Also
  /// - [_formatType] – for type alias formatting.
  /// - [`MethodElement.formalParameters`](https://pub.dev/documentation/analyzer/latest/dart_element_element/ExecutableElement/formalParameters.html)
  /// - [`ParameterElement`](https://pub.dev/documentation/analyzer/latest/dart_element_element/ParameterElement-class.html)
  String _buildParameterSignatureWithTypes(MethodElement method, Map<Uri, String> aliasMap, [Map<TypeParameterElement, DartType>? typeSubst]) {
    final parts = <String>[];
    final requiredPos = method.formalParameters
        .where((p) => !p.isNamed && !p.isOptionalPositional)
          .map((p) => '${_formatType(p.type, aliasMap, typeSubst)} ${p.name}')
        .toList();
    if (requiredPos.isNotEmpty) parts.addAll(requiredPos);

    final optionalPos = method.formalParameters
        .where((p) => p.isOptionalPositional)
        .map((p) {
          final def = (p.defaultValueCode != null && p.defaultValueCode!.isNotEmpty) ? ' = ${p.defaultValueCode}' : '';
          return '${_formatType(p.type, aliasMap, typeSubst)} ${p.name}$def';
        })
        .toList();
    if (optionalPos.isNotEmpty) parts.add('[${optionalPos.join(', ')}]');

    final named = method.formalParameters.where((p) => p.isNamed).map((p) {
      final req = p.isRequiredNamed ? 'required ' : '';
      final def = (p.defaultValueCode != null && p.defaultValueCode!.isNotEmpty) ? ' = ${p.defaultValueCode}' : '';
      return '$req${_formatType(p.type, aliasMap, typeSubst)} ${p.name}$def';
    }).toList();
    if (named.isNotEmpty) parts.add('{${named.join(', ')}}');

    return parts.join(', ');
  }

  /// Builds a comma-separated argument list used for invoking a proxied method.
  ///
  /// This function mirrors the parameter structure of a method call expression
  /// (`delegate.someMethod(...)`), ensuring that both **positional** and
  /// **named** parameters are correctly expanded when generating proxy method
  /// bodies.
  ///
  /// ### Example
  /// Given a method:
  /// ```dart
  /// void log(String message, {bool pretty = false});
  /// ```
  /// The generated invocation arguments will be:
  /// ```
  /// message, pretty: pretty
  /// ```
  ///
  /// ### Behavior
  /// - Combines positional and named parameters in declaration order.
  /// - Skips optional brackets (`[]` or `{}`) since the call site does not require them.
  /// - Ensures valid argument syntax when both positional and named arguments coexist.
  ///
  /// ### Parameters
  /// - [method] — The [MethodElement] describing the function to invoke.
  ///
  /// ### Returns
  /// A valid comma-separated argument list (e.g., `"x, y, flag: flag"`).
  ///
  /// ### See Also
  /// - [_buildParameterSignatureWithTypes] — for generating parameter declarations.
  /// - [_namedArgsMap] — for building named-argument maps used in interception metadata.
  String _buildInvocationArgs(MethodElement method) {
    final pos = method.formalParameters.where((p) => !p.isNamed).map((p) => p.name).join(', ');
    final named = method.formalParameters.where((p) => p.isNamed).map((p) => '${p.name}: ${p.name}').join(', ');
    if (pos.isNotEmpty && named.isNotEmpty) return '$pos, $named';
    return pos.isNotEmpty ? pos : named;
  }

  /// Builds a simple, comma-separated list of **positional arguments**.
  ///
  /// This helper is typically used when creating interception metadata objects
  /// (e.g., [`MethodArguments`]) to represent the list of positional parameters
  /// in the original invocation.
  ///
  /// ### Example
  /// For a method:
  /// ```dart
  /// void add(int a, int b, {bool log = false});
  /// ```
  /// Returns:
  /// ```
  /// a, b
  /// ```
  ///
  /// ### Parameters
  /// - [method] — The [MethodElement] from which to extract positional parameters.
  ///
  /// ### Returns
  /// A comma-separated string of positional argument identifiers.
  ///
  /// ### See Also
  /// - [_namedArgsMap] — builds a corresponding representation for named arguments.
  /// - [`MethodArguments.positionalArgs`]
  String _positionalArgsList(MethodElement method) =>
      method.formalParameters.where((p) => !p.isNamed).map((p) => p.name).join(', ');

  /// Builds a map literal representation of **named arguments**.
  ///
  /// This is primarily used in JetLeaf’s interception mechanism, where named
  /// arguments must be passed to the [`MethodArguments`] object to preserve
  /// runtime call context during method interception.
  ///
  /// ### Example
  /// For a method:
  /// ```dart
  /// void greet(String name, {int age = 0, bool polite = true});
  /// ```
  /// Returns:
  /// ```
  /// 'age': age, 'polite': polite
  /// ```
  ///
  /// ### Parameters
  /// - [method] — The [MethodElement] whose named parameters are to be represented.
  ///
  /// ### Returns
  /// A string suitable for embedding in Dart map literal syntax.
  ///
  /// ### See Also
  /// - [_positionalArgsList] — for positional argument serialization.
  /// - [`MethodArguments.namedArgs`]
  String _namedArgsMap(MethodElement method) =>
      method.formalParameters.where((p) => p.isNamed).map((p) => "'${p.name}': ${p.name}").join(', ');

  /// Determines whether the given [type] represents an asynchronous return type.
  ///
  /// This includes both `Future<T>` and `FutureOr<T>` types. It is used by
  /// the proxy generator to decide whether to emit `async` modifiers in
  /// generated method signatures and interception wrappers.
  ///
  /// ### Example
  /// ```dart
  /// _isAsyncLike(Future<int>)     → true
  /// _isAsyncLike(FutureOr<void>)  → true
  /// _isAsyncLike(String)          → false
  /// ```
  ///
  /// ### Parameters
  /// - [type] — The [DartType] being analyzed.
  ///
  /// ### Returns
  /// `true` if the type begins with `Future` or `FutureOr`, otherwise `false`.
  ///
  /// ### References
  /// - [`Future`](https://api.dart.dev/stable/dart-async/Future-class.html)
  /// - [`FutureOr`](https://api.dart.dev/stable/dart-async/FutureOr-class.html)
  bool _isAsyncLike(DartType type) {
    final display = type.getDisplayString(withNullability: false);
    return display.startsWith('Future') || display.startsWith('FutureOr');
  }
}

/// {@template property_indication}
/// # Property Indication
///
/// Represents metadata for a single property (field, getter, or setter)
/// discovered during JetLeaf proxy generation.
///
/// This class acts as a lightweight descriptor that captures:
/// - The **name** of the property
/// - The **declared Dart type** of the property
/// - An optional reference to the **Dart element** ([Element]) providing
///   access to annotations, modifiers, or source information.
///
/// It is used internally by [ProxyGenerator] to determine which
/// properties of a class should be forwarded or proxied in the generated
/// subclass. For example, a `PropertyIndication` instance may correspond
/// to:
///
/// ```dart
/// class Example {
///   final String id;
///   int get count => _count;
///   set count(int value) => _count = value;
/// }
/// ```
///
/// During generation, each of these members would produce a corresponding
/// [PropertyIndication] used to emit proxy forwarding code:
///
/// ```dart
/// final id = PropertyIndication('id', DartType(String));
/// final countGetter = PropertyIndication('count', DartType(int));
/// final countSetter = PropertyIndication('count', DartType(void));
/// ```
///
/// ---
///
/// ## Fields
/// - [name] → Identifier of the property (e.g., `'id'`)
/// - [type] → The Dart type of the property (e.g., `String`, `int`)
/// - [element] → Optional [Element] from the analyzer providing richer metadata
///
/// ---
///
/// ## Usage in Code Generation
/// The [ProxyGenerator] collects all [PropertyIndication]s when scanning
/// supertypes, interfaces, and mixins to emit getters and setters like:
///
/// ```dart
/// @override
/// String get id => delegate.id;
///
/// @override
/// set count(int value) => delegate.count = value;
/// ```
///
/// ---
///
/// ## See also
/// - [ProxyGenerator] — uses `PropertyIndication` to generate proxy fields
/// - [ClassElement] — the analyzer class from which these indications derive
///
/// {@endtemplate}
class PropertyIndication {
  /// The name (identifier) of the property (e.g., `'id'`, `'count'`).
  final String name;

  /// The declared type of the property (e.g., `String`, `int`, `User`).
  final DartType type;

  /// The optional analyzer element that declares this property.
  ///
  /// This may be a [FieldElement], [PropertyAccessorElement],
  /// or another [Element] subtype, depending on whether the
  /// property is a field, getter, or setter.
  final Element? element;

  /// Creates a new [PropertyIndication] instance.
  ///
  /// Typically constructed internally by the [ProxyGenerator]
  /// during class scanning.
  /// 
  /// {@macro property_indication}
  PropertyIndication(this.name, this.type, [this.element]);
}

/// Determines whether the given [ClassElement] or any of its supertypes
/// already includes or inherits from JetLeaf's [`Interceptable`] mixin.
///
/// This check ensures that the proxy generator does not redundantly apply
/// the `Interceptable` mixin to classes that already provide interception
/// support through inheritance or composition.
///
/// ### Behavior
/// - Traverses all supertypes (superclasses, interfaces, mixins) of the class.
/// - Compares by both type name (`'Interceptable'`) and source library URI
///   (must match `jetleaf_core/intercept.dart`).
///
/// ### Example
/// ```dart
/// mixin Interceptable {}
/// 
/// class Base with Interceptable {}
/// class Derived extends Base {}
///
/// _hasInterceptableMixinOrSuper(Derived) → true
/// ```
///
/// ### Parameters
/// - [cls] — The target [ClassElement] to inspect.
///
/// ### Returns
/// `true` if the class directly mixes in or inherits from
/// `Interceptable`, otherwise `false`.
///
/// ### See Also
/// - [`Interceptable`](https://jetleaf.hapnium.com/docs/core/interception)
/// - [_generateProxyForClass] — where this check prevents redundant mixin injection.
bool _hasInterceptableMixinOrSuper(ClassElement cls) {
  for (final st in cls.allSupertypes) {
    final element = st.element;
    if (element.name == 'Interceptable' && element.library.uri.toString() == _INTERCEPT_URI.toString()) {
      return true;
    }
  }
  return false;
}

/// Extracts the *inner type* (or “tie type”) from a return type for use
/// in proxy interception signatures.
///
/// This method is primarily used when wrapping asynchronous methods within
/// JetLeaf’s interception mechanism, ensuring that proxy-generated calls
/// preserve the correct return type for intercepted methods.
///
/// ### Behavior
/// - If the return type is `Future<T>` or `FutureOr<T>`, returns `T` as formatted.
/// - If it is an untyped `Future` or `FutureOr`, defaults to `dynamic`.
/// - If the type is `void`, preserves `void`.
/// - Otherwise, returns the formatted display type as-is.
///
/// ### Example
/// ```dart
/// _extractTieType(Future<int>, aliasMap)      → int
/// _extractTieType(FutureOr<String?>, aliasMap) → String?
/// _extractTieType(Future, aliasMap)            → dynamic
/// _extractTieType(void, aliasMap)              → void
/// _extractTieType(User, aliasMap)              → User
/// ```
///
/// ### Parameters
/// - [returnType] — The [DartType] representing a method’s declared return type.
/// - [aliasMap] — A map of imported library URIs to their assigned aliases,
///   used to correctly qualify type references during code generation.
///
/// ### Returns
/// A formatted Dart type string representing the inner resolved type for
/// use within generated `when<T>()` interceptors or async wrappers.
///
/// ### See Also
/// - [_isAsyncLike] — detects whether a method requires async handling.
/// - [_emitMethodOverride] — uses this to infer `when<T>` generic types.
/// - [`MethodInterceptorDispatcher.when`] — the interception API this supports.
String _extractTieType(DartType returnType, Map<Uri, String> aliasMap, [Map<TypeParameterElement, DartType>? typeSubst]) {
  // If Future<T> or FutureOr<T> keep T exactly as formatted (including '?')
  if (returnType is ParameterizedType && returnType.typeArguments.isNotEmpty) {
    final first = returnType.typeArguments.first;
    return _formatType(first, aliasMap, typeSubst);
  }

  // If declared Future or FutureOr with no type args -> dynamic
  final displayNoNull = returnType.getDisplayString(withNullability: false);
  if (displayNoNull == 'Future' || displayNoNull == 'FutureOr') return 'dynamic';

  if (displayNoNull == 'void') return 'void';

  // Otherwise simply format the returnType (this preserves nullable like 'String?')
  return _formatType(returnType, aliasMap, typeSubst);
}

void _writeHeader(StringBuffer buffer, String libraryName) {
  // ASCII art as raw string
  const asciiArt = r'''
// 🍃      _      _   _                __  ______  
// 🍃     | | ___| |_| |    ___  __ _ / _| \ \ \ \ 
// 🍃  _  | |/ _ \ __| |   / _ \/ _` | |_   \ \ \ \
// 🍃 | |_| |  __/ |_| |__|  __/ (_| |  _|  / / / /
// 🍃  \___/ \___|\__|_____\___|\__,_|_|   /_/_/_/ 
// 🍃
''';

  buffer.writeln('''
// ignore_for_file: unused_import, depend_on_referenced_packages, duplicate_import, deprecated_member_use, unnecessary_import
//
${asciiArt.trim()}
//
// AUTO-GENERATED proxy for [$libraryName] package
// Do not edit manually.
//
// ---------------------------------------------------------------------------
// JetLeaf Framework 🍃
//
// Copyright (c) ${DateTime.now().year} Hapnium & JetLeaf Contributors
//
// Licensed under the MIT License. See LICENSE file in the root of the jetleaf project
//
// This file is part of the JetLeaf Framework, a modern, modular backend
// framework for Dart.
//
// For documentation and usage, visit:
// https://jetleaf.hapnium.com/docs
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃
''');
}

/// Generates a safe, deterministic alias for a library [Uri].
///
/// This aliasing strategy prevents namespace collisions and ensures
/// valid Dart identifiers when multiple libraries are imported with
/// similar paths.
///
/// ### Behavior
/// Converts URIs such as:
/// - `package:foo/bar/baz.dart` → `pkg_foo_bar_baz`
/// - `dart:async` → `pkg_async`
///
/// The resulting alias:
/// - Removes URI schemes (`package:`, `dart:`, `file:`)
/// - Removes `.dart` suffixes
/// - Replaces all non-alphanumeric characters with underscores.
///
/// ### Example
/// ```dart
/// final uri = Uri.parse('package:my_lib/src/utils/helper.dart');
/// print(_aliasForUri(uri)); // pkg_my_lib_src_utils_helper
/// ```
///
/// ### Returns
/// A valid Dart identifier safe to use as an import alias.
///
/// ### See Also
/// - [_formatType] — uses the alias map to resolve qualified type names.
/// - [_collectUrisForClass] — populates the set of URIs that need aliasing.
String _aliasForUri(Uri uri) {
  // For package: URIs, use package name + rest
  final s = uri.toString();
  final withoutScheme = s.replaceAll(RegExp(r'(^.*:)|(\.dart$)'), ''); // remove scheme and .dart
  final safe = withoutScheme.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  return 'pkg_$safe';
}

/// Formats a [DartType] for source emission, applying the correct alias
/// from [aliasMap] when possible and preserving nullability and generics.
///
/// This ensures that all generated proxy code consistently refers to
/// external types via their aliased imports rather than raw, potentially
/// ambiguous names.
///
/// ### Behavior
/// - Handles primitive and built-in types (`void`, `dynamic`) directly.
/// - For [InterfaceType]s, prefixes the type with the alias of its source library.
/// - Recursively formats generic type arguments.
/// - Preserves `?` for nullable types.
///
/// ### Example
/// ```dart
/// _formatType(List<int>, aliasMap) → "pkg_core.List<int>"
/// _formatType(User?, aliasMap)     → "pkg_models.User?"
/// ```
///
/// ### See Also
/// - [_aliasForUri]
/// - [_typeReferencesInternalLibrary]
String _formatType(DartType t, Map<Uri, String> aliasMap, [Map<TypeParameterElement, DartType>? typeSubst]) {
  // fast-path for primitive-ish display strings
  final displayNullable = t.getDisplayString(withNullability: true);
  final displayNoNull = t.getDisplayString(withNullability: false);

  // If this is a type parameter and we have a substitution mapping, return the substituted type
  if (t is TypeParameterType) {
    final elem = t.element;
    if (typeSubst != null && typeSubst.containsKey(elem)) {
      // Substitute and preserve use-site nullability (e.g., T? -> Empty?)
      final substituted = typeSubst[elem]!;
      var formatted = _formatType(substituted, aliasMap, typeSubst);
      // If the use-site type parameter was nullable (e.g., T?), ensure the substituted
      // representation keeps the '?' if it isn't already present.
      final useSite = t.getDisplayString(withNullability: true);
      if (useSite.endsWith('?') && !formatted.endsWith('?')) {
        formatted = '$formatted?';
      }
      return formatted;
    }
    // Otherwise, render the parameter name (preserve nullability)
    return displayNullable;
  }

  if (displayNoNull.toLowerCase() == "dynamic") return 'dynamic';
  if (displayNoNull.toLowerCase() == "void") return 'void';

  // For InterfaceType we want to produce "pkg_x.Name<...>?" preserving `?`
  if (t is InterfaceType) {
    final elem = t.element;
    final libUri = elem.library.uri;
    final name = elem.name ?? displayNoNull;

    String base;
    if (aliasMap.containsKey(libUri) && !_typeReferencesInternalLibrary(t)) {
      base = '${aliasMap[libUri]}.$name';
    } else {
      base = name;
    }

    if (t.typeArguments.isNotEmpty) {
      final args = t.typeArguments.map((a) => _formatType(a, aliasMap, typeSubst)).join(', ');
      base = '$base<$args>';
    }

    // preserve nullability by comparing display with nullability
    final withNull = t.getDisplayString(withNullability: true);
    final withoutNull = t.getDisplayString(withNullability: false);
    final suffix = withNull.endsWith('?') && !withoutNull.endsWith('?') ? '?' : '';
    return '$base$suffix';
  }

  // Function types, typedefs, type parameters, etc. — fall back to the safe representation
  return displayNullable;
}

/// Determines whether a given [Uri] corresponds to an internal or
/// private Dart SDK library (e.g., `dart:_http`).
///
/// These libraries cannot be imported directly by user code, so
/// the generator must skip producing import statements for them.
///
/// ### Example
/// ```dart
/// _isInternalSdkUri(Uri.parse('dart:_http')) → true
/// _isInternalSdkUri(Uri.parse('dart:async')) → false
/// ```
///
/// ### Returns
/// `true` if the URI starts with `dart:_`, otherwise `false`.
bool _isInternalSdkUri(Uri uri) {
  // internal / private SDK libraries look like dart:_http, dart:_internal, etc.
  if (uri.scheme == 'dart') {
    final path = uri.path; // e.g. '_http'
    if (path.startsWith('_')) return true;
  }

  return false;
}

/// Recursively checks whether a [DartType] or any of its generic
/// parameters reference an internal SDK library.
///
/// This conservative check prevents generated code from attempting to
/// qualify internal types using aliases that cannot be imported.
///
/// ### Example
/// ```dart
/// _typeReferencesInternalLibrary(List<_HttpRequest>) → true
/// _typeReferencesInternalLibrary(Future<String>)     → false
/// ```
///
/// ### Returns
/// `true` if any referenced library URI is internal/private.
bool _typeReferencesInternalLibrary(DartType? t) {
  if (t == null) return false;
  if (t is InterfaceType) {
    final libUri = t.element.library.uri;
    if (_isInternalSdkUri(libUri)) return true;
    for (final a in t.typeArguments) {
      if (_typeReferencesInternalLibrary(a)) return true;
    }
  }
  // function types or typedefs may refer to param types; conservatively check their display string:
  return false;
}

/// Determines whether a method's return type should be intercepted
/// using the JetLeaf `when()` mechanism.
///
/// Interceptable return types include:
/// - `void` (always intercepted for lifecycle tracking)
/// - `Future<T>`
/// - `FutureOr<T>`
///
/// ### Example
/// ```dart
/// _isInterceptableReturnType(Future<int>) → true
/// _isInterceptableReturnType(void)        → true
/// _isInterceptableReturnType(String)      → false
/// ```
///
/// ### See Also
/// - [_emitMethodOverride] — wraps methods whose return types are interceptable.
bool _isInterceptableReturnType(DartType type) {
  final display = type.getDisplayString(withNullability: false);
  final low = display.toLowerCase();
  return low == 'void' || low.startsWith('future') || low.startsWith('futureor');
}

/// Collects the URIs of all libraries referenced by a given [ClassElement],
/// including supertypes, interfaces, field types, and method parameter/return
/// types.
///
/// This ensures that all dependent libraries are properly imported with aliases
/// in the generated proxy file.
///
/// ### Behavior
/// - Adds the class's own library URI.
/// - Traverses all supertypes and their libraries.
/// - Includes all field and method type dependencies.
/// - Skips private or internal SDK URIs (`dart:_*`).
///
/// ### Example
/// ```dart
/// _collectUrisForClass(MyService)
/// → { package:my_app/models/user.dart, package:jetleaf_core/intercept.dart, ... }
/// ```
///
/// ### Returns
/// A set of URIs representing all external libraries required for proxy code generation.
///
/// ### See Also
/// - [_aliasForUri]
/// - [_formatType]
Set<Uri> _collectUrisForClass(ClassElement cls) {
  final set = <Uri>{};
  void addType(DartType? t) {
    if (t == null) return;
    if (t is InterfaceType) {
      final libUri = t.element.library.uri;
      // skip internal SDK private libs
      if (!_isInternalSdkUri(libUri)) {
        set.add(libUri);
      }
      for (final a in t.typeArguments) {
        addType(a);
      }
    }
  }

  // class library
  final classLibUri = cls.library.uri;
  set.add(classLibUri);

  // super types
  for (final st in cls.allSupertypes) {
    final libUri = st.element.library.uri;
    if (!_isInternalSdkUri(libUri)) set.add(libUri);
  }

  // fields
  for (final f in cls.fields) {
    if (f.isStatic) continue;
    addType(f.type);
    final libUri = f.library.uri;
    if (!_isInternalSdkUri(libUri)) set.add(libUri);
  }

  // methods + parameter types + return types
  for (final m in cls.methods) {
    if (m.isStatic) continue;
    addType(m.returnType);
    for (final p in m.formalParameters) {
      addType(p.type);
    }
    final libUri = m.library.uri;
    if (!_isInternalSdkUri(libUri)) set.add(libUri);
  }

  // also include implemented interfaces' libraries
  for (final st in cls.allSupertypes) {
    final libUri = st.element.library.uri;
    if (!_isInternalSdkUri(libUri)) set.add(libUri);
  }

  return set;
}

/// Writes structured and sorted `import` statements into the provided
/// [StringBuffer] for code generation.
///
/// This function ensures all necessary Dart and package imports — including
/// user-defined, JetLeaf core, and dynamically generated ones — are organized
/// and formatted in a clean, deterministic order before the runtime
/// bootstrap file is written.
///
/// Import ordering rules:
/// 1. All `dart:` imports are written first (alphabetically).
/// 2. A blank line separates system imports from `package:` imports.
/// 3. Generated package imports receive unique aliases (e.g., `pkg_example`)
///    to avoid name collisions.
/// 4. The user’s main entry file import is always written last as:
///    ```dart
///    import '<packageUri>' as user_main_lib;
///    ```
///
/// Example:
/// ```dart
/// final buffer = StringBuffer();
/// _writeImports(buffer, 'package:my_app/main.dart', [
///   'package:my_app/src/services/api_service.dart',
///   'package:my_app/src/models/user.dart',
/// ]);
/// print(buffer.toString());
/// ```
///
/// Output:
/// ```dart
/// import 'dart:io';
///
/// import 'package:jetleaf/jetleaf.dart';
/// import 'package:jetleaf_lang/lang.dart';
/// import 'package:my_app/src/models/user.dart' as pkg_user;
/// import 'package:my_app/src/services/api_service.dart' as pkg_api_service;
///
/// import 'package:my_app/main.dart' as user_main_lib;
/// ```
///
/// Parameters:
/// - [buffer]: The output buffer where formatted imports are written.
/// - [packageUri]: The URI of the user’s main library (usually the entry file).
/// - [generatedImports]: A list of discovered or auto-generated import URIs.
///
/// Notes:
/// - Duplicate imports are automatically deduplicated using a `Set`.
/// - Generated imports receive safe alias names derived from their file names.
/// - Default JetLeaf core libraries are always included automatically.
void _writeImports(StringBuffer buffer, Iterable<String> generatedImports, {bool aliased = true}) {
  // All imports including user main
  final imports = generatedImports.toSet();

  // Split into dart: imports and others
  final dartImports = imports.where((i) => i.startsWith('dart:')).toList()..sort();
  final packageImports = imports.where((i) => !i.startsWith('dart:')).toList()..sort();

  // Write dart: imports first
  for (final i in dartImports) {
    buffer.writeln("import '$i';");
  }

  if (dartImports.isNotEmpty && packageImports.isNotEmpty) {
    buffer.writeln(); // blank line between dart: and package:
  }

  // Write package imports with aliases for generated imports
  for (final i in packageImports) {
    if (generatedImports.contains(i)) {
      // Generate a safe alias like pkg_example
      buffer.writeln("import '$i'${aliased ? ' as ${_buildImportAlias(i)}' : ''};");
    } else {
      buffer.writeln("import '$i';");
    }
  }

  buffer.writeln();
}

/// Build a safe import alias from an import path.
///
/// Examples:
///  - package:glob/list_local_fs.dart -> pkg_glob_list_local_fs
///  - package:my-lib/src/foo/bar.dart -> pkg_my_lib_bar
///  - dart:async -> dart_async
///  - ../utils/file-helper.dart -> utils_file_helper
String _buildImportAlias(String importPath, {Set<String>? used}) {
  String sanitize(String s) {
    // keep letters, digits and underscores only
    var out = s.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    return out;
  }

  String alias;
  if (importPath.startsWith('package:')) {
    final pkgAndPath = importPath.substring('package:'.length); // e.g. "glob/list_local_fs.dart"
    final parts = pkgAndPath.split('/');
    final pkgName = parts.first.replaceAll('-', '_'); // "glob" or "my-lib" -> "my_lib"
    final fileName = parts.last.split('.').first.replaceAll('-', '_'); // "list_local_fs.dart" -> "list_local_fs"
    alias = 'pkg_${sanitize(pkgName)}_${sanitize(fileName)}';
  } else if (importPath.startsWith('dart:')) {
    alias = 'dart_${sanitize(importPath.substring('dart:'.length))}';
  } else {
    // relative path or other scheme -> sanitize whole string and remove path separators
    final cleaned = importPath.replaceAll(RegExp(r'[/\\]+'), '_');
    alias = sanitize(cleaned);
  }

  // Optional: avoid collisions by appending suffix _2, _3, ...
  if (used != null) {
    var base = alias;
    var i = 2;
    while (used.contains(alias) && alias.isNotEmpty) {
      alias = '${base}_$i';
      i++;
    }
    used.add(alias);
  }

  return alias;
}