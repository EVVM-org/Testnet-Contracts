# Auto-Publish Setup

Este repositorio tiene configurada la publicación automática a NPM en cada commit a la rama `main`.

## Configuración requerida

### 1. NPM Token
Necesitas crear un token de NPM y agregarlo como secreto en GitHub:

1. Ve a [npmjs.com](https://www.npmjs.com) y haz login
2. Ve a tu perfil → Access Tokens
3. Crea un nuevo token con permisos de "Automation"
4. En GitHub, ve a Settings → Secrets and variables → Actions
5. Agrega un nuevo secreto llamado `NPM_TOKEN` con el valor del token

### 2. Permisos del repositorio
El workflow ya está configurado con los permisos necesarios para:
- Escribir en el repositorio (commits automáticos)
- Crear releases
- Acceder a packages

## Cómo funciona

1. **Trigger**: Se ejecuta en cada push a `main` (excepto cambios solo en README, docs, o .github)
2. **Versioning**: Incrementa automáticamente la versión patch (0.0.1)
3. **Publishing**: 
   - Copia los archivos desde `src/` al root
   - Publica a NPM
   - Limpia los archivos copiados
4. **Git**: Hace commit de la nueva versión con `[skip-publish]` para evitar loops
5. **Release**: Crea un release en GitHub con la nueva versión

## Evitar publicación automática

Si quieres hacer un commit sin publicar, incluye `[skip-publish]` en el mensaje del commit:

```bash
git commit -m "fix: minor bug [skip-publish]"
```

## Estructura del paquete publicado

```
@evvm/testnet-contracts/
├── contracts/
├── interfaces/
├── library/
├── LICENSE
├── README.md
└── package.json
```

## Versioning automático

- Cada commit incrementa la versión patch: `1.0.4` → `1.0.5`
- Para cambios major/minor, actualiza manualmente en package.json antes del commit