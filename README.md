# Documentación del Proyecto Terraform para Desplegar Máquinas Virtuales en Azure

## Introducción

En este documento, describo en primera persona el proceso que seguí para crear una infraestructura en Azure utilizando Terraform. El objetivo era desplegar dos máquinas virtuales, una con Windows Server y otra con Ubuntu, cada una con su respectiva configuración de red y seguridad.

---

## **1. Preparación del Entorno**

Antes de empezar con Terraform, aseguré que mi entorno tuviera las herramientas necesarias:

- **Terraform**: Para definir y gestionar la infraestructura como código.
- **Azure CLI**: Para interactuar con Azure desde la línea de comandos.
- **Cuenta de Azure**: Con permisos suficientes para crear recursos.

Para verificar que Terraform estaba instalado, ejecuté:

```bash
terraform -version
```

Y para validar Azure CLI:

```bash
az version
```

---

## **2. Autenticación en Azure**

Para que Terraform pudiera desplegar recursos en Azure, necesitaba autenticación. Opté por usar un **Service Principal**, que creé con Azure CLI:

```bash
az login
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/TU-SUBSCRIPTION-ID"
```

Este comando me devolvió las credenciales necesarias (client_id, client_secret, subscription_id y tenant_id), que guardé en un archivo seguro (`secrets.tfvars`).

---

## **3. Creación del Proyecto Terraform**

Decidí organizar mi proyecto en la siguiente estructura de archivos:

```
proyecto-terraform-vms/
├── main.tf
├── variables.tf
├── outputs.tf
└── secrets.tfvars
```

- **`main.tf`**: Define los recursos en Azure.
- **`variables.tf`**: Contiene variables reutilizables.
- **`outputs.tf`**: Muestra valores útiles tras la ejecución.
- **`secrets.tfvars`**: Almacena credenciales sensibles (agregado a `.gitignore`).

---

## **4. Configuración de los Archivos**

### **Archivo `main.tf`**

Aquí definí los siguientes recursos en Azure:

- **Grupo de Recursos**: Donde se crearán los recursos.
- **Red Virtual y Subred**: Para alojar las máquinas virtuales.
- **IPs Públicas**: Para conectarme externamente a las VMs.
- **Network Security Groups (NSG)**: Para controlar el tráfico entrante.
- **Máquina Virtual Windows**: Con acceso RDP.
- **Máquina Virtual Ubuntu**: Con acceso SSH.

### **Archivo `variables.tf`**

Este archivo me permitió parametrizar valores como el tamaño de las VMs, credenciales y configuración de red.

### **Archivo `outputs.tf`**

Aquí definí las salidas de Terraform para ver información clave después del despliegue, como las direcciones IP de las máquinas virtuales.

### **Archivo `secrets.tfvars`**

Almacené mis credenciales de Azure y configuraciones específicas de las VMs, asegurándome de NO subir este archivo al repositorio.

---

## **5. Configuración de SSH para Ubuntu**

Para conectarme a la VM Ubuntu de forma segura, generé una clave SSH:

```bash
ssh-keygen -t rsa -b 4096
```

Luego, añadí la clave pública al archivo `secrets.tfvars` y la privada la usé para conectarme a la VM.

---

## **6. Inicialización y Aplicación de Terraform**

Con todo configurado, ejecuté los siguientes comandos en el directorio del proyecto:

```bash
# Inicializar Terraform
terraform init

# Validar la configuración
terraform validate

# Revisar el plan de ejecución
terraform plan -var-file=secrets.tfvars

# Aplicar la configuración y crear los recursos
terraform apply -var-file=secrets.tfvars
```

Este proceso tomó unos minutos, y al finalizar, obtuve la IP pública de cada máquina en la salida de Terraform.

---

## **7. Conexión a las Máquinas Virtuales**

Después de la implementación, me conecté a las VMs de la siguiente manera:

- **Windows**:  
  Utilicé **Escritorio Remoto (RDP)** con la IP pública y credenciales definidas en `secrets.tfvars`.

- **Ubuntu**:  
  Me conecté por SSH usando la clave privada generada:

  ```bash
  ssh -i ~/.ssh/id_rsa adminuser@IP_PUBLICA_UBUNTU
  ```

---

## **8. Consideraciones de Seguridad**

Para proteger mis credenciales y la infraestructura:

✔ **Agregué `secrets.tfvars` al archivo `.gitignore`** para evitar subirlo a Git.

El cual debe contener las siguientes variables:

subscription_id = ""
client_id = ""
tenant_id = ""
client_secret = ""

windows_admin_username = ""
windows_admin_password = ""
ubuntu_admin_username = ""
ubuntu_ssh_public_key_path = "pathToRSAKey"

project_prefix = "proyectovm"
location = "zona"

---

## **9. Eliminación de los Recursos**

Cuando ya no necesité la infraestructura, la eliminé fácilmente con:

```bash
terraform destroy -var-file=secrets.tfvars
```

Este comando borró todos los recursos creados en Azure.

---
