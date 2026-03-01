# GuitarrApp - Instrucciones para Claude Code

## 🎯 Visión del Proyecto

**GuitarrApp** es una aplicación móvil para aprender guitarra tocando y recibiendo feedback en tiempo real de IA.

**MVP Core:** Tocas la guitarra → La IA te escucha → Te dice si lo hiciste bien o qué corregir

## 📁 Estructura de Documentación

```
.claude/
├── agents/           # Instrucciones específicas por agente
│   ├── pm.md         # Product Manager
│   ├── ux.md         # UX Designer  
│   ├── frontend.md   # Frontend Developer
│   └── backend.md    # Backend Developer
docs/
├── mvp/
│   ├── ROADMAP.md    # Roadmap completo del MVP
│   └── USER_STORIES.md
└── technical/
    └── ARCHITECTURE.md
```

## 🤖 Cómo Usar los Agentes

Para trabajar como un agente específico, usa el comando:

```bash
claude "Actúa como el agente [PM/UX/Frontend/Backend]. Lee tus instrucciones en .claude/agents/[agente].md y ejecuta las tareas del Sprint [N]"
```

### Ejemplos:

```bash
# Iniciar como PM y planificar Sprint 0
claude "Actúa como PM. Lee .claude/agents/pm.md y comienza el Sprint 0"

# Trabajar en frontend del Sprint 1
claude "Actúa como Frontend. Lee .claude/agents/frontend.md y ejecuta las tareas del Sprint 1"

# Diseñar UX del flujo principal
claude "Actúa como UX. Lee .claude/agents/ux.md y diseña el happy path"
```

## 🚀 Quick Start

1. **Ver el roadmap completo:** `cat docs/mvp/ROADMAP.md`
2. **Ver tareas de un sprint:** Buscar "Sprint N" en el roadmap
3. **Actuar como agente:** Leer el archivo correspondiente en `.claude/agents/`

## 📋 Estado Actual del Proyecto

- **Sprint Actual:** 0 (Discovery)
- **Próximo Milestone:** POC de captura de audio + detección de notas
- **Bloqueadores:** Ninguno

## ⚡ Comandos Útiles

```bash
# Ejecutar la app
flutter run

# Tests
flutter test

# Analizar código
flutter analyze

# Ver estructura del proyecto
find lib -type f -name "*.dart" | head -20
```

## 🎯 Primer Objetivo (Sprint 0)

> "Abro la app → Toco una cuerda → Veo en pantalla qué nota fue"

Para lograr esto necesitamos:
1. ✅ Captura de audio del micrófono (Frontend)
2. ✅ Modelo de detección de notas (Backend)  
3. ✅ UI que muestre la nota detectada (Frontend)
4. ✅ Flujo de permisos de micrófono (Frontend)
