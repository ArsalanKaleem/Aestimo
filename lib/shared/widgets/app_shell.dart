import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import 'app_logo.dart';

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label, this.route);
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
}

const _navItems = <_NavItem>[
  _NavItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Dashboard',
      AppRoutes.dashboard),
  _NavItem(Icons.description_outlined, Icons.description_rounded, 'Resume',
      AppRoutes.upload),
  _NavItem(Icons.insights_outlined, Icons.insights_rounded, 'Insights',
      AppRoutes.insights),
  _NavItem(
      Icons.forum_outlined, Icons.forum_rounded, 'AI Chat', AppRoutes.chat),
  _NavItem(Icons.psychology_outlined, Icons.psychology_rounded, 'Interview',
      AppRoutes.interview),
  _NavItem(
      Icons.work_outline_rounded, Icons.work_rounded, 'Jobs', AppRoutes.jobs),
  _NavItem(Icons.mail_outline_rounded, Icons.mail_rounded, 'Cover Letter',
      AppRoutes.coverLetter),
  _NavItem(Icons.score_outlined, Icons.score_rounded, 'Resume Score',
      AppRoutes.resumeScore),
  _NavItem(Icons.auto_fix_high_outlined, Icons.auto_fix_high_rounded,
      'ATS Resume', AppRoutes.atsResume),
];

const _secondaryItems = <_NavItem>[
  _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'About',
      AppRoutes.about),
  _NavItem(Icons.settings_outlined, Icons.settings_rounded, 'Settings',
      AppRoutes.settings),
];

/// Adaptive navigation shell wrapping every authenticated screen.
///
/// - Desktop / tablet → persistent [NavigationRail]
/// - Mobile           → top [AppBar] + slide-out [Drawer] with every feature
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  int _indexForLocation(String location) {
    final i = _navItems.indexWhere((n) => location.startsWith(n.route));
    return i < 0 ? 0 : i;
  }

  String _titleForLocation(String location) {
    for (final n in [..._navItems, ..._secondaryItems]) {
      if (location.startsWith(n.route)) return n.label;
    }
    return AppConstants.appName;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = _indexForLocation(location);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shadow = isDark ? AppColorsDark.shadow : AppColorsLight.shadow;

    if (context.isMobile) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: theme.colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          shadowColor: shadow,
          iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
          titleSpacing: 0,
          title: Text(
            _titleForLocation(location),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        drawer: _AppDrawer(location: location),
        body: SafeArea(top: false, child: child),
      );
    }

    final extended = context.isDesktop;
    return Scaffold(
      body: Row(
        children: [
          _SideRail(selected: selected, extended: extended),
          const VerticalDivider(width: 1),
          Expanded(child: SafeArea(child: child)),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
//  Mobile drawer
// ───────────────────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.location});
  final String location;

  bool _isActive(String route) {
    // Exact-ish match so '/upload' doesn't light up for unrelated routes.
    return location == route || location.startsWith('$route/');
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop(); // close the drawer first
    if (!_isActive(route)) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      width: 296,
      child: Column(
        children: [
          const _DrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              children: [
                for (final n in _navItems)
                  _DrawerTile(
                    item: n,
                    active: _isActive(n.route),
                    onTap: () => _go(context, n.route),
                  ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 4),
                  child: Divider(height: 1),
                ),
                for (final n in _secondaryItems)
                  _DrawerTile(
                    item: n,
                    active: _isActive(n.route),
                    onTap: () => _go(context, n.route),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: _DrawerTile(
              item: const _NavItem(Icons.logout_rounded, Icons.logout_rounded,
                  'Sign out', AppRoutes.login),
              active: false,
              danger: true,
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.login);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The gradient banner is brand-fixed (same in both themes), so this widget
/// needs no dark-mode branching — `AppColors.secondary`/`brandGradient` are
/// intentionally constant regardless of brightness.
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.of(context).padding.top + AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.secondary, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppConstants.tagline,
            style: TextStyle(
              color: AppColors.secondary.withValues(alpha: 0.92),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.active,
    required this.onTap,
    this.danger = false,
  });

  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primary = theme.colorScheme.primary;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;
    final dangerColor = isDark ? AppColors.dangerDark : AppColors.danger;

    final fg = danger
        ? dangerColor
        : active
            ? primary
            : textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  active ? item.activeIcon : item.icon,
                  size: 22,
                  color: danger ? dangerColor : fg,
                ),
                const SizedBox(width: 14),
                Text(
                  item.label,
                  style: TextStyle(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (active)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
//  Desktop / tablet side rail
// ───────────────────────────────────────────────────────────────────────────

class _SideRail extends StatelessWidget {
  const _SideRail({required this.selected, required this.extended});
  final int selected;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primary = theme.colorScheme.primary;
    final primarySoft =
        isDark ? AppColorsDark.primarySoft : AppColorsLight.primarySoft;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;

    return Container(
      width: extended ? 248 : 88,
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
            child: AppLogo(size: 26, showWordmark: extended),
          ),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              itemCount: _navItems.length,
              itemBuilder: (context, i) {
                final n = _navItems[i];
                final isActive = i == selected;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Material(
                    color: isActive ? primarySoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      onTap: () => context.go(n.route),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: extended ? 14 : 0,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: extended
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            Icon(
                              isActive ? n.activeIcon : n.icon,
                              size: 22,
                              color: isActive ? primary : textSecondary,
                            ),
                            if (extended) ...[
                              const SizedBox(width: 12),
                              Text(
                                n.label,
                                style: TextStyle(
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isActive ? primary : textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          _RailTile(
            icon: Icons.person_outline_rounded,
            label: 'About',
            extended: extended,
            onTap: () => context.go(AppRoutes.about),
          ),
          _RailTile(
            icon: Icons.settings_outlined,
            label: 'Settings',
            extended: extended,
            onTap: () => context.go(AppRoutes.settings),
          ),
          _RailTile(
            icon: Icons.logout_rounded,
            label: 'Sign out',
            extended: extended,
            onTap: () => context.go(AppRoutes.login),
            bottom: true,
          ),
        ],
      ),
    );
  }
}

/// A compact action row used at the bottom of the desktop side rail.
class _RailTile extends StatelessWidget {
  const _RailTile({
    required this.icon,
    required this.label,
    required this.extended,
    required this.onTap,
    this.bottom = false,
  });

  final IconData icon;
  final String label;
  final bool extended;
  final VoidCallback onTap;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        bottom ? AppSpacing.sm : 0,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: extended ? 14 : 0,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment:
                  extended ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: textSecondary),
                if (extended) ...[
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
