import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../repositories/catalog_repository.dart';
import '../../repositories/sales_repository.dart';
import '../home/home_screen.dart';
import '../warehouse/almacen_screen.dart';

/// Pantalla de Menú Inicial con las 2 opciones principales:
/// 1. Almacén (Lista completa de productos dividida por categorías)
/// 2. Boleta (Menú de boleta para sacar cuentas y registrar ventas)
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  static const Color _almacenBlue = Color(0xFF4368C7);

  @override
  Widget build(BuildContext context) {
    final catalogRepo = CatalogRepository();
    final salesRepo = SalesRepository();

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.liquor_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text('LICORERÍA POS'),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          maxWidth: 640,
          child: ListenableBuilder(
            listenable: Listenable.merge([catalogRepo, salesRepo]),
            builder: (context, _) {
              final totalProducts = catalogRepo.products.length;
              final totalCategories = CatalogRepository.categories.length;
              final totalSales = salesRepo.sales.length;
              final totalAmount = salesRepo.totalSalesAmount;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabecera de bienvenida con el ícono de la app
                      Column(
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _almacenBlue.withValues(alpha: 0.35),
                                  blurRadius: 22,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/icon.png',
                              width: 78,
                              height: 78,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Container(
                                decoration: const BoxDecoration(
                                  color: _almacenBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '¿Qué deseas abrir hoy?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Selecciona una opción para ver tu almacén o calcular una boleta',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // OPCIÓN 1: ALMACÉN
                      _MainOptionCard(
                        title: 'ALMACÉN',
                        subtitle:
                            'Ver la lista de todos tus productos divididos por categorías',
                        badgeText:
                            '$totalProducts productos • $totalCategories categorías',
                        icon: Icons.warehouse_rounded,
                        accentColor: const Color(0xFF5A82E8),
                        gradientColors: const [
                          Color(0xFF2B4C9E),
                          Color(0xFF1D3573),
                        ],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AlmacenScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // OPCIÓN 2: BOLETA
                      _MainOptionCard(
                        title: 'BOLETA',
                        subtitle:
                            'Menú de boleta para sacar cuentas, registrar ventas y ver historial',
                        badgeText: totalSales > 0
                            ? '$totalSales ${totalSales == 1 ? "venta activa" : "ventas activas"} • S/. ${totalAmount.toStringAsFixed(2)}'
                            : 'Listo para sacar cuentas',
                        icon: Icons.receipt_long_rounded,
                        accentColor: AppColors.primary,
                        gradientColors: const [
                          AppColors.primary,
                          AppColors.primaryDark,
                        ],
                        isLightForeground: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              settings: const RouteSettings(name: '/boleta'),
                              builder: (_) => const HomeScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MainOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
  final bool isLightForeground;
  final VoidCallback onTap;

  const _MainOptionCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
    this.isLightForeground = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isLightForeground ? Colors.black : Colors.white;
    final subtitleColor = isLightForeground
        ? Colors.black.withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.82);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // Ícono principal
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isLightForeground
                        ? Colors.black.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icon,
                    size: 34,
                    color: titleColor,
                  ),
                ),
                const SizedBox(width: 18),

                // Textos y badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isLightForeground
                              ? Colors.black.withValues(alpha: 0.14)
                              : Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 20,
                  color: titleColor.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

