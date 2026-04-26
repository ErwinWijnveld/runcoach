import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/organization/data/organization_api.dart';
import 'package:app/features/organization/models/membership.dart';
import 'package:app/features/organization/models/organization.dart';

part 'membership_provider.g.dart';

@riverpod
Future<List<Membership>> memberships(Ref ref) async {
  final api = ref.watch(organizationApiProvider);
  final response = await api.listMemberships() as Map<String, dynamic>;
  final list = response['data'] as List<dynamic>;
  return list
      .map((e) => Membership.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

@riverpod
Future<List<Organization>> organizationSearch(Ref ref, String query) async {
  if (query.trim().length < 2) return [];

  final api = ref.watch(organizationApiProvider);
  final response =
      await api.searchOrganizations(query.trim()) as Map<String, dynamic>;
  final list = response['data'] as List<dynamic>;
  return list
      .map((e) => Organization.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

@riverpod
class MembershipActions extends _$MembershipActions {
  @override
  void build() {}

  Future<void> acceptInvite(int id) async {
    await ref.read(organizationApiProvider).acceptInvite(id);
    _refreshAll();
  }

  Future<void> acceptInviteByToken(String token) async {
    await ref.read(organizationApiProvider).acceptInviteByToken(token);
    _refreshAll();
  }

  Future<void> rejectInvite(int id) async {
    await ref.read(organizationApiProvider).rejectInvite(id);
    _refreshAll();
  }

  Future<void> requestJoin(int organizationId) async {
    await ref
        .read(organizationApiProvider)
        .requestJoin({'organization_id': organizationId});
    _refreshAll();
  }

  Future<void> cancelRequest(int id) async {
    await ref.read(organizationApiProvider).cancelRequest(id);
    _refreshAll();
  }

  Future<void> leave() async {
    await ref.read(organizationApiProvider).leaveOrganization();
    _refreshAll();
  }

  void _refreshAll() {
    ref.invalidate(membershipsProvider);
    ref.invalidate(authProvider);
  }
}
