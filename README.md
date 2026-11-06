<div align="center">
  <img src="assets/images/icon.png" alt="Licorería POS Logo" width="110" />

  # 🍾 Licorería POS — Sistema de Punto de Venta & Almacén

  **Aplicación multiplataforma de Punto de Venta (POS) y gestión de catálogo desarrollada en Flutter para licorerías y minimarkets.**

  ![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
  ![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
  ![Android](https://img.shields.io/badge/Android-APK-3DDC84?style=for-the-badge&logo=android&logoColor=white)
  ![Web](https://img.shields.io/badge/Web-PWA-4285F4?style=for-the-badge&logo=google-chrome&logoColor=white)
  ![Offline First](https://img.shields.io/badge/Modo-100%25_Offline-F59E0B?style=for-the-badge)
</div>

---

## 📋 Descripción General

**Licorería POS** es una solución ágil, moderna y **100% funcional sin conexión a internet (Offline-First)** pensada para agilizar la atención en mostrador, controlar los precios del almacén y llevar el cuadre exacto de ventas diarias diferenciando entre **Efectivo**, **Yape** y **Tarjeta de Crédito**.

Al iniciar la aplicación tras su pantalla de carga animada, el sistema presenta **2 módulos principales**:
1. 📦 **Almacén**: Visualización completa del inventario organizado por categorías, buscador inteligente en tiempo real y creación de nuevos productos con fotografía.
2. 🧾 **Boleta (Punto de Venta)**: Registro rápido de ventas, cálculo automático de totales por método de pago, historial interactivo y generación/guardado de boletas electrónicas.

---

## ✨ Características Principales

### 📦 1. Módulo de Almacén y Catálogo
- **Organización por 14 Categorías Oficiales**: Vista estructurada con encabezados, contadores e íconos distintivos por categoría.
- **Subcategorías Especializadas**: División rápida de *Cervezas* en **Botellas** y **Latas**.
- **Creación de Productos desde la App (`+ Añadir Producto`)**:
  - Selección visual de categoría y subcategoría.
  - Ingreso de nombre y ajuste rápido de precios en Soles (`S/.`).
  - Subida de fotografía del producto desde la galería del teléfono o selector de archivos.
- **Buscador Inteligente con Tolerancia a Errores**: Búsqueda instantánea por nombre o marca en todo el catálogo.

### 💳 2. Módulo de Boleta y Métodos de Pago
- ** Panel de Métricas en Tiempo Real**: Muestra el **Total General** recaudado y el desglose inmediato en:
  - 💵 **Efectivo**
  - 📱 **Yape**
  - 💳 **Tarjeta de Crédito** (con cálculo automático de **+5% de comisión**)
- **División de Pagos (`Efectivo + Yape`)**: Permite tocar cualquier venta en efectivo para dividir el cobro cuando un cliente paga una parte en efectivo y el resto por Yape.
- **Combinación de Transferencias Yape**: Permite agrupar múltiples ventas de Yape en una sola transferencia o separarlas cuando sea necesario.

### 🧾 3. Emisión, Revisión y Exportación de Boletas
- **Vista Previa de Boleta (`Revisar Boleta`)**: Resumen numerado de productos (`DESCRIPCIÓN | Cantidad | TOTAL`), desglose por modalidad de pago y total general.
- **Historial de Boletas Guardadas**: Almacenamiento de boletas emitidas con numeración correlativa (`B001-000001`), fecha y hora.
- **Exportación e Impresión PDF**: Generación de tickets en formato PDF listos para compartir por WhatsApp o imprimir.

---

## 🗂️ Categorías del Catálogo

| # | Categoría | Descripción / Ejemplos |
| :-: | :--- | :--- |
| 1 | 🥤 **Bebidas** | Gaseosas personales y familiares, aguas minerales, energizantes y rehidratantes |
| 2 | 🍪 **Galletas** | Galletas dulces, saladas y wafers |
| 3 | 🍟 **Frituras** | Snacks, papas fritas, piqueos y chifles |
| 4 | 🌿 **Chicles y mentas** | Mentas y gomas de mascar |
| 5 | 🚬 **Cigarrillos** | Cajetillas y cigarrillos sueltos |
| 6 | 🍷 **Vino** | Vinos tintos, borgoña, semi secos y sangrías |
| 7 | 🥃 **Pisco** | Piscos puros, acholados y quebranta |
| 8 | 🍸 **Vodkas** | Vodkas clásicos y saborizados |
| 9 | 🥃 **Ron** | Rones rubios, negros, blancos y chatas |
| 10 | 🍺 **Cervezas** | Subdividido en **Botellas** y **Latas** (unidades y Six Packs) |
| 11 | 🍹 **Bebidas alcohólicas preparadas** | RTDs, chilcanos en lata, Four Loko, Mike's, Smirnoff Ice |
| 12 | 🥃 **Whisky** | Whiskies escoceses, blends y bourbon |
| 13 | 📦 **Combos** | Packs promocionales listos con licor + gaseosa + hielo |
| 14 | 🧊 **Hielo** | Bolsas de hielo en cubos gourmet |

---

## 🏗️ Estructura del Proyecto

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_colors.dart          # Paleta de colores oscura, azul real y dorado ámbar
│   ├── services/
│   │   └── boleta_pdf_service.dart  # Servicio generador de boletas en PDF
│   ├── theme/
│   │   └── app_theme.dart           # Configuración global de Material 3
│   └── utils/
│       ├── image_picker_helper.dart # Selector multiplataforma de imágenes (Android/Web/Desktop)
│       └── responsive_layout.dart   # Adaptación responsiva para móvil, tablet y web
├── models/
│   ├── boleta.dart                  # Modelo de boleta emitida y numeración correlativa
│   ├── category.dart                # Modelo de categoría y subcategoría
│   ├── product.dart                 # Modelo de producto del catálogo
│   └── sale.dart                    # Modelo de registro de venta
├── presentation/
│   ├── boletas/
│   │   └── boletas_screen.dart      # Historial de boletas guardadas y exportación PDF
│   ├── categories/
│   │   ├── categories_screen.dart   # Menú de categorías para registrar ventas
│   │   ├── category_detail_screen.dart
│   │   └── widgets/                 # Tarjetas de productos y modal de cobro rápido
│   ├── home/
│   │   ├── home_screen.dart         # Pantalla de Boleta (Métricas, Nueva Venta, Historial)
│   │   └── widgets/                 # Modales de boleta, división Efectivo/Yape y métricas
│   ├── menu/
│   │   └── main_menu_screen.dart    # Menú principal con las 2 opciones: Almacén y Boleta
│   ├── splash/
│   │   └── splash_screen.dart       # Pantalla de carga animada al iniciar la app
│   ├── subcategories/
│   │   └── subcategories_screen.dart
│   └── warehouse/
│       ├── almacen_screen.dart      # Pantalla de Almacén dividida por categorías
│       └── widgets/
│           └── add_product_modal.dart # Modal para crear nuevos productos con imagen
├── repositories/
│   ├── boletas_repository.dart      # Persistencia de boletas emitidas
│   ├── catalog_repository.dart      # Gestión del catálogo JSON + productos personalizados
│   └── sales_repository.dart        # Gestión del historial de ventas y cálculos por pago
└── main.dart                        # Punto de entrada de la aplicación
```

---

## 🛠️ Tecnologías y Dependencias

- **[Flutter](https://flutter.dev/) & [Dart](https://dart.dev/)**: Framework UI multiplataforma con soporte Material 3.
- **[shared_preferences](https://pub.dev/packages/shared_preferences)**: Almacenamiento persistente local para historial de ventas, boletas emitidas y nuevos productos creados en el almacén.
- **[pdf](https://pub.dev/packages/pdf) & [printing](https://pub.dev/packages/printing)**: Creación, previsualización, impresión y envío de boletas en formato PDF.
- **[intl](https://pub.dev/packages/intl)**: Formateo de fechas, horas y moneda local (`S/.`).

---

## 🚀 Instalación y Ejecución

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/TU_USUARIO/Licoreria-Flutter.git
   cd Licoreria-Flutter
   ```

2. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```

3. **Ejecutar en modo desarrollo (Móvil, Emulador o Navegador Web):**
   ```bash
   flutter run
   ```

4. **Compilar el instalador APK para Android (Release):**
   ```bash
   flutter build apk --release
   ```
   > El archivo APK generado se encontrará en: `build/app/outputs/flutter-apk/app-release.apk`

---

<div align="center">
  Desarrollado por <b>Jerycoop Ernesto Vidal Solano</b> — <b>Licorería POS</b>
</div>
