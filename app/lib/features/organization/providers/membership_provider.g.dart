// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(memberships)
final membershipsProvider = MembershipsProvider._();

final class MembershipsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Membership>>,
          List<Membership>,
          FutureOr<List<Membership>>
        >
    with $FutureModifier<List<Membership>>, $FutureProvider<List<Membership>> {
  MembershipsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'membershipsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$membershipsHash();

  @$internal
  @override
  $FutureProviderElement<List<Membership>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Membership>> create(Ref ref) {
    return memberships(ref);
  }
}

String _$membershipsHash() => r'df85ef0c8987a41f0f8865c1a283059c72423675';

@ProviderFor(OrganizationSearch)
final organizationSearchProvider = OrganizationSearchFamily._();

final class OrganizationSearchProvider
    extends $AsyncNotifierProvider<OrganizationSearch, OrganizationPage> {
  OrganizationSearchProvider._({
    required OrganizationSearchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'organizationSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$organizationSearchHash();

  @override
  String toString() {
    return r'organizationSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OrganizationSearch create() => OrganizationSearch();

  @override
  bool operator ==(Object other) {
    return other is OrganizationSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$organizationSearchHash() =>
    r'fdd5fe8ae8a8cb005f235746250a0d87701f4724';

final class OrganizationSearchFamily extends $Family
    with
        $ClassFamilyOverride<
          OrganizationSearch,
          AsyncValue<OrganizationPage>,
          OrganizationPage,
          FutureOr<OrganizationPage>,
          String
        > {
  OrganizationSearchFamily._()
    : super(
        retry: null,
        name: r'organizationSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrganizationSearchProvider call(String query) =>
      OrganizationSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'organizationSearchProvider';
}

abstract class _$OrganizationSearch extends $AsyncNotifier<OrganizationPage> {
  late final _$args = ref.$arg as String;
  String get query => _$args;

  FutureOr<OrganizationPage> build(String query);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<OrganizationPage>, OrganizationPage>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OrganizationPage>, OrganizationPage>,
              AsyncValue<OrganizationPage>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(MembershipActions)
final membershipActionsProvider = MembershipActionsProvider._();

final class MembershipActionsProvider
    extends $NotifierProvider<MembershipActions, void> {
  MembershipActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'membershipActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$membershipActionsHash();

  @$internal
  @override
  MembershipActions create() => MembershipActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$membershipActionsHash() => r'f44704ed4aa1622fe1e1355fb53951c6d6197303';

abstract class _$MembershipActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
