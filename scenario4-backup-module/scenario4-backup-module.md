
# Scenario #4: Enterprise Backup Policy with AWS Backup

Para asegurar que todos los datos importantes esten respaldados con protecciones tipo WORM, copias en otras regiones y cuentas, y un criterio claro para escoger que se respalda y que no. Para ello esta AWS Backup y con esta config de Terraform permite automatizar el proceso de punta a punta.

----------

1.  **Backup Vault con Vault Lock (WORM)**
    
    -   Esto significa que, una vez bloqueado, nadie puede borrar o alterar los backups dentro de la ventana de retención. Evita borrados malintencionados o errores humanos.
        
2.  **Plan de Backup** (incluyendo copias cruzadas a otras regiones y cuentas)
    
    -   Si tu centro de datos principal sufre un desastre (ej.: una región completa de AWS cae), la copia en otra región o cuenta te garantiza que tus datos siguen a salvo.
        
3.  **Selección de recursos basada en Tags** (por ejemplo, `ToBackup=true`)
    
    -   De esta forma, no necesitas especificar manualmente cada recurso (EBS, RDS, DynamoDB, etc.). Solo le pones la etiqueta “ToBackup” a lo que quieras respaldar y AWS Backup lo incluye automáticamente.
        
4.  **Cifrado con KMS**
    
    -   Tus respaldos se cifran usando la clave KMS que elijas, asegurándote de cumplir normativas o políticas internas sobre cifrado.
  
## Archivos de Configuración

### 1. `variables.tf`
-   `vault_name`: Darle un nombre al “baúl” de backups.
    
-   `backup_role_arn`: Rol de IAM que tendrá permisos para realizar y gestionar los respaldos.
    
-   `cross_region_copy` & `cross_account_copy`: Listas de configuraciones que dicen: “¿A qué región/cuenta quieres mandar tus respaldos? ¿Por cuánto tiempo los retendrás? ¿Qué clave KMS se usa para cifrarlos?”.
    
-   `selection_tags`: El conjunto de etiquetas (por ejemplo, `ToBackup="true"`, `Owner="ops@company.com"`) que AWS Backup usará para saber si un recurso entra o no al plan.
### 2. `main.tf`
-   **`aws_backup_vault.this`**: Crea el contenedor principal de respaldos. Lo cifra con la primera clave KMS que pases en `cross_region_copy`.
    
-   **`aws_backup_vault_lock_configuration`**: Activa la política tipo WORM (Vault Lock). Nadie puede borrar estos backups dentro del período configurado.
    
-   **`aws_backup_plan.plan`**: Define un plan de backup diario (`schedule = \"cron(0 5 * * ? *)\"` → todos los días a las 5 AM).
    
    -   **`rule_name = \"daily\"`**: una etiqueta para identificar la regla.
        
    -   **`lifecycle { delete_after = 30 }`**: tras 30 días, se pueden borrar los backups.
        
    -   **Copias cruzadas**: se definen con `copy_action` en bucle dinámico. Terraform crea una acción de copia por cada objeto en la lista `cross_region_copy` o `cross_account_copy`.
        
-   **`aws_backup_selection.selection`**: Selecciona qué recursos se respaldan, basándose en tags.

### 3. `example_usage.tf`
-   Muestra cómo puedes “invocar” el módulo anterior en tu infraestructura.
    
-   Le pasas los valores concretos (`vault_name`, `backup_role_arn`, etc.) y Terraform se encarga de hacer el resto.