# Aerie Helm Chart

A Helm chart for deploying [NASA-AMMOS Aerie](https://github.com/NASA-AMMOS/aerie), a mission planning and sequencing system.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.8.0+
- [Task](https://taskfile.dev/) (optional, for development)

## Installation

### From OCI Registry

```bash
helm install aerie oci://registry.platform.intelligent.space/aerie/aerie-helm --version 0.1.0
```

### From Source

```bash
git clone <repository-url>
cd aerie-helm
helm install aerie .
```

### With Custom Values

```bash
helm install aerie oci://registry.platform.intelligent.space/aerie/aerie-helm \
  --version 0.1.0 \
  -f my-values.yaml
```

## Configuration

See [values.yaml](values.yaml) for the full list of configurable parameters.

Key configuration sections:

| Section      | Description                          |
| ------------ | ------------------------------------ |
| `postgres`   | PostgreSQL database settings         |
| `hasura`     | Hasura GraphQL engine configuration  |
| `merlin`     | Merlin server and worker settings    |
| `scheduler`  | Scheduler server and worker settings |
| `sequencing` | Sequencing service configuration     |
| `gateway`    | API gateway settings                 |
| `ui`         | Aerie UI configuration               |
| `istio`      | Istio VirtualService configuration   |

### Istio Integration

This chart includes optional [Istio](https://istio.io/) support via a VirtualService that routes traffic to all Aerie services. Istio is **disabled by default**.

To enable Istio:

```yaml
# values.yaml or custom values file
istio:
  enabled: true
  host: aerie.example.com
  gateway: istio-system/default-gateway
  corsPolicy:
    allowOrigins:
      - exact: https://aerie.example.com
    allowMethods:
      - GET
      - POST
      - PUT
      - DELETE
      - OPTIONS
```

Or via command line:

```bash
helm install aerie . --set istio.enabled=true --set istio.host=aerie.example.com
```

**Prerequisites for Istio:**

- Istio installed in the cluster
- An Istio Gateway resource must exist (referenced by `istio.gateway`)
- The namespace should have Istio sidecar injection enabled (if using mTLS)

The VirtualService configures routing for:

- `/v1/graphql`, `/v1/query`, `/console` → Hasura
- `/api/*` → Gateway
- `/auth/*`, `/file`, `/health` → Gateway
- `/action/*` → Action server
- `/workspace/*` → Workspace server
- `/*` (default) → UI

## Development

This project uses [Task](https://taskfile.dev/) for common operations:

```bash
# List available tasks
task --list

# Lint the chart
task lint

# Package the chart
task package

# Push to OCI registry
task push

# Show current version
task version

# Bump version
task bump-patch   # 0.0.X
task bump-minor   # 0.X.0
task bump-major   # X.0.0
```

## Releasing

```bash
# Login to registry (first time)
task login

# Create a release (tags git, packages, and pushes)
task release
```

## Components

This chart deploys the following Aerie components:

- **PostgreSQL** - Database backend
- **Hasura** - GraphQL API layer
- **Merlin Server/Worker** - Planning and simulation engine
- **Scheduler Server/Worker** - Activity scheduling
- **Sequencing** - Sequence generation service
- **Action** - Action service
- **Workspace** - Workspace management
- **Gateway** - API gateway
- **UI** - Web interface

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
