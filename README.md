# AWS + Lambda Integration


## Instalación y despliegue

### Clonar el repositorio y acceder a la carpeta `iac`
```bash
git clone https://github.com/ninelgod/iac_04
cd iac-lab04
```

## Configurar credenciales
aws configure --profile "perfil"
```bash
- AWS Access Key ID: 
- AWS Secret Access Key:
- Default region name: us-east-1
- Default output format: json
```
## Verifica que las credenciales funcionan:
```bash
aws sts get-caller-identity --profile perfil
```


## Inicializar
```bash 
cd iac 
```
```bash 
terraform init 
```

##  Crear workspaces (solo la primera vez)
```bash
terraform workspace new dev
```
```bash
terraform workspace new qa
```
```bash
terraform workspace new prod
```
##  Seleccionar el entorno deseado (ejemplo: dev)
```bash
terraform workspace select dev
```
##  Verificar que el workspace activo es el correcto
```bash
terraform workspace show
```
## Revisar el plan (opcional pero recomendable)
```bash
terraform plan
```

## Aplicar los cambios
```bash
terraform apply -auto-approve
```
Te mostrará outputs al final del despliegue, utiliza la URL de `api_url` para las pruebas

### Reemplaza el link y la ruta de la imagen para poder subirla
```bash
curl -X POST "el link"/upload \
  -H "Content-Type: multipart/form-data" \
  -F "image=@/la ruta de tla imagen"
```
Te mostrará un mensaje de confirmación, entonces se subió la imagen y ya está procesada para la reducción de tamaño.

## Como último paso destruiremos la infraestructura
```bash
terraform destroy -auto-approve
```