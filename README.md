# 💈 BarberIA: Estilista Facial con Inteligencia Artificial

BarberIA es una solución diseñada para transformar la experiencia de consulta en barberías y salones de belleza. La aplicación combina la potencia de la Inteligencia Artificial para asesoría estética con un sistema robusto de Gestión de Clientes, permitiendo a los profesionales administrar su negocio y visualizar resultados antes del primer corte.

## 🚀 Características Principales

* **Asesoría con IA:** Integración con **Google Gemini API** para análisis de fisionomía y recomendaciones de estilo personalizadas basadas en la estructura facial del usuario.
* **Gestión de Clientes (CRUD):** Sistema completo de administración que permite:
    * **Create:** Registro de nuevos clientes con datos de perfil.
    * **Read:** Consulta de listas de clientes e historiales de análisis.
    * **Update:** Edición de información personal y preferencias.
    * **Delete:** Eliminación de registros para mantenimiento de base de datos.
* **Arquitectura Serverless:** Backend construido con **Firebase Cloud Functions** para un procesamiento seguro.
  
## 🛠️ Stack Tecnológico
- **Frontend:** Flutter & Dart.
- **Inteligencia Artificial:** Gemini 2.5 Flash Image Preview.
- **Backend/Cloud:** Firebase (Cloud Functions, Firestore Database, Authentication, Cloud Storage).

## 🌐 Arquitectura y Repositorios

Para garantizar un código limpio, el proyecto se divide en dos módulos independientes:

1.  **Mobile App (Este repositorio):** Contiene toda la interfaz de usuario, lógica de cliente y persistencia de datos.
2.  **AI Service Backend:** Repositorio independiente con la lógica de Cloud Functions en TypeScript para el análisis facial.
    * 🔗 [Ver Repositorio del Backend aquí](https://github.com/JosueEspinoza19/barber-ia-functions.git)

## 📦 Estructura de este Proyecto

* **`/lib`**: Código fuente de la aplicación móvil (UI, Modelos y Lógica de Servicios).
* **`/assets`**: Identidad visual, iconos y recursos de diseño del proyecto.
* **`firebase.json` / `.firebaserc`**: Archivos de configuración para la conexión con los servicios de Firebase.

---
*Proyecto desarrollado para la materia de Desarrollo de Aplicaciones Innovadoras - UABC.*
