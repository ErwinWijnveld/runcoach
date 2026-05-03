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

class OrganizationPage {
  final List<Organization> items;
  final bool hasMore;
  final int page;

  const OrganizationPage({
    required this.items,
    required this.hasMore,
    required this.page,
  });
}

@riverpod
class OrganizationSearch extends _$OrganizationSearch {
  static const _perPage = 25;
  String _query = '';
  int _nextPage = 1;
  bool _hasMore = true;
  bool _loading = false;
  List<Organization> _items = const [];

  @override
  Future<OrganizationPage> build(String query) async {
    _query = query.trim();
    _nextPage = 1;
    _hasMore = true;
    _items = const [];

    final page = await _fetch(1);
    _items = page.items;
    _hasMore = page.hasMore;
    _nextPage = page.hasMore ? 2 : 1;
    return OrganizationPage(
      items: List.unmodifiable(_items),
      hasMore: _hasMore,
      page: 1,
    );
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loading) return;
    _loading = true;
    try {
      final page = await _fetch(_nextPage);
      _items = [..._items, ...page.items];
      _hasMore = page.hasMore;
      _nextPage = page.hasMore ? _nextPage + 1 : _nextPage;
      state = AsyncValue.data(
        OrganizationPage(
          items: List.unmodifiable(_items),
          hasMore: _hasMore,
          page: _nextPage - 1,
        ),
      );
    } finally {
      _loading = false;
    }
  }

  Future<OrganizationPage> _fetch(int page) async {
    final api = ref.read(organizationApiProvider);
    final response = await api.searchOrganizations(
      _query.isEmpty ? null : _query,
      page,
      _perPage,
    ) as Map<String, dynamic>;
    final list = response['data'] as List<dynamic>;
    final meta = (response['meta'] as Map?) ?? const {};
    return OrganizationPage(
      items: list
          .map(
            (e) => Organization.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      hasMore: meta['has_more'] == true,
      page: page,
    );
  }
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
