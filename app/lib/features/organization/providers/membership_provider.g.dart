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

@ProviderFor(organizationSearch)
final organizationSearchProvider = OrganizationSearchFamily._();

final class OrganizationSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Organization>>,
          List<Organization>,
          FutureOr<List<Organization>>
        >
    with
        $FutureModifier<List<Organization>>,
        $FutureProvider<List<Organization>> {
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
  $FutureProviderElement<List<Organization>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Organization>> create(Ref ref) {
    final argument = this.argument as String;
    return organizationSearch(ref, argument);
  }

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
    r'65f3a307533a17fe7168dd5b2864d0e6080dd127';

final class OrganizationSearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Organization>>, String> {
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
