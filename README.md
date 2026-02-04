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

## 📦 Estructura del Proyecto

* **`/lib`**: Código fuente de la aplicación móvil (UI, Modelos y Lógica de Servicios).
* **`/functions`**: Lógica de backend (funcion de analisis) para la comunicación segura con servicios externos.
* **`/assets`**: Identidad visual, iconos y recursos de diseño del proyecto.

*Proyecto desarrollado para la materia de Desarrollo de Aplicaciones Innovadoras - UABC.*
