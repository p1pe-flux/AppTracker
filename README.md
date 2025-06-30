# 🏋️‍♂️ WorkoutTracker

> Una aplicación iOS para el seguimiento y análisis de entrenamientos personalizados

[![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-14.0+-blue.svg)](https://developer.apple.com/xcode/)

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Instalación](#-instalación)
- [Arquitectura](#-arquitectura)
- [Uso](#-uso)
- [Contribución](#-contribución)
- [Roadmap](#-roadmap)

## ✨ Características

### Funcionalidades Actuales
- [ ] Gestión de ejercicios personalizados
- [ ] Seguimiento de entrenamientos
- [ ] Registro de series (peso, repeticiones, tiempo de descanso)
- [ ] Historial de entrenamientos

### Funcionalidades Planificadas
- [ ] Estadísticas y gráficos de progreso
- [ ] Temporizador de descanso
- [ ] Plantillas de entrenamiento
- [ ] Exportación de datos
- [ ] Sincronización en la nube

## 🛠 Instalación

### Requisitos Previos
- Xcode 14.0 o superior
- iOS 15.0 o superior
- Swift 5.5+

### Configuración del Proyecto

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tuusuario/WorkoutTracker.git
   cd WorkoutTracker
   ```

2. **Abrir en Xcode**
   ```bash
   open WorkoutTracker.xcodeproj
   ```

3. **Configurar equipo de desarrollo**
   - Selecciona tu equipo en Project Settings → Signing & Capabilities
   - Cambia el Bundle Identifier si es necesario

4. **Ejecutar la aplicación**
   - Selecciona un simulador o dispositivo
   - Presiona `Cmd + R` para ejecutar

## 🏗 Arquitectura

### Estructura del Proyecto

```
WorkoutTracker/
├── 📁 App/                    # Configuración principal de la app
├── 📁 Core/                   # Funcionalidades centrales
│   ├── 📁 Database/           # CoreData stack y persistencia
│   ├── 📁 Models/             # Modelos de datos
│   └── 📁 Extensions/         # Extensiones de Swift
├── 📁 Features/               # Módulos de funcionalidades
│   ├── 📁 Exercises/          # Gestión de ejercicios
│   ├── 📁 Workouts/           # Seguimiento de entrenamientos
│   └── 📁 Statistics/         # Análisis y estadísticas
├── 📁 Shared/                 # Componentes compartidos
│   ├── 📁 Components/         # UI Components reutilizables
│   ├── 📁 Utils/              # Utilidades y helpers
│   └── 📁 Constants/          # Constantes de la aplicación
└── 📁 Resources/              # Recursos (imágenes, etc.)
```

### Patrones de Diseño
- **MVVM (Model-View-ViewModel)**: Separación de responsabilidades
- **Repository Pattern**: Abstracción de la capa de datos
- **Dependency Injection**: Gestión de dependencias
- **Observer Pattern**: Comunicación reactiva con Combine

### Tecnologías Utilizadas
- **SwiftUI**: Framework de interfaz de usuario
- **CoreData**: Persistencia de datos local
- **Combine**: Programación reactiva
- **Swift Package Manager**: Gestión de dependencias

## 📱 Uso

### Gestión de Ejercicios
1. Crear nuevos ejercicios con nombre, categoría y grupos musculares
2. Editar ejercicios existentes
3. Organizar por categorías

### Seguimiento de Entrenamientos
1. Iniciar un nuevo entrenamiento
2. Seleccionar ejercicios
3. Registrar series con peso, repeticiones y tiempo de descanso
4. Finalizar y guardar el entrenamiento

## 🤝 Contribución

### Flujo de Trabajo

1. **Fork del proyecto**
2. **Crear rama para feature**
   ```bash
   git checkout -b feature/nueva-funcionalidad
   ```
3. **Hacer commits siguiendo convenciones**
   ```bash
   git commit -m "feat(exercises): add exercise search functionality"
   ```
4. **Push a la rama**
   ```bash
   git push origin feature/nueva-funcionalidad
   ```
5. **Crear Pull Request**

### Convenciones de Código
- Usar SwiftLint para mantener consistencia
- Seguir las convenciones de nomenclatura de Swift
- Documentar funciones públicas
- Escribir tests unitarios para nueva funcionalidad

### Estructura de Commits
Seguimos [Conventional Commits](https://www.conventionalcommits.org/):
```
<type>(<scope>): <description>

Ejemplos:
feat(exercises): add exercise creation form
fix(workouts): resolve timer not stopping issue
docs(readme): update installation instructions
```

## 🗺 Roadmap

### Versión 1.0 (MVP) - En Desarrollo
- [x] Configuración del proyecto
- [ ] Gestión básica de ejercicios
- [ ] Seguimiento de entrenamientos
- [ ] Registro de series

### Versión 1.1 - Mejoras UX
- [ ] Temporizador de descanso
- [ ] Búsqueda y filtrado
- [ ] Mejoras en la interfaz

### Versión 1.2 - Analytics
- [ ] Estadísticas de progreso
- [ ] Gráficos de rendimiento
- [ ] Exportación de datos

### Versión 2.0 - Características Avanzadas
- [ ] Plantillas de entrenamiento
- [ ] Sincronización en la nube
- [ ] Compartir entrenamientos

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

## 📞 Contacto

- **Autor**: Tu Nombre
- **Email**: tu.email@ejemplo.com
- **GitHub**: [@tuusuario](https://github.com/tuusuario)

## 🙏 Agradecimientos

- Comunidad iOS por las mejores prácticas
- Recursos de diseño y UX
- Beta testers y feedback

---

⭐ Si te gusta este proyecto, ¡dale una estrella en GitHub!
