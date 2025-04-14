
# Scenario #1: Encryption Management & Key Rotation

>A continuación, muestro **dos formas distintas** de afrontar esto, basadas en mi experiencia resolviendo problemas de cifrado en entornos productivos.

----------

## Approach A: Activar la Rotación Automática + Re-Encriptado en Caliente

**1. Rotación automática cada año**  
En AWS KMS, basta con poner `enable_key_rotation = true`. Te olvidas de renovar la clave manualmente; AWS se encarga de crear una nueva versión al cabo de 365 días. Ideal para no romperte la cabeza con fechas.

**2. Alias inalterables**  
Si ya usas alias (por ejemplo, `alias/app-data-prod`), no necesitas cambiar nada en tu código, porque el alias siempre apuntará a la versión de la clave que AWS KMS crea cada año.

**3. Re-encriptado en caliente**  
Los datos ya existentes —hablo de archivos en S3, snapshots de RDS, tablas de DynamoDB, etc.— se pueden “migrar” a la nueva clave de manera gradual. ¿Cómo? Con un **script de Python** muy simple (reencrypt.py), que básicamente vuelve a copiar objetos de S3 usando la nueva clave. En RDS, se haría con comandos de AWS CLI o un job planificado. La idea es que hagas esto sin apagar nada.

**4. Sin prisa, pero sin pausa**  
La ventaja es que puedes hacerlo por tandas (por ejemplo, primero un bucket, luego otro). Así, si ocurre un contratiempo, no se te rompe todo a la vez.

----------

## Approach B: Blue-Green Rotation (Staged Cutover)

He visto este enfoque en empresas más grandes y con auditorías muy estrictas:

**1. Crea la nueva clave**  
Le pones un alias distinto (`alias/app-key-v2`) y dejas la vieja (`alias/app-key-v1`) activa.

**2. Apunta tus apps a la clave nueva**  
Cambia la config en tus microservicios o lambdas para usar la v2. Si algo va mal, siempre estás a tiempo de volver a la v1 sin mayor lío.

**3. Re-encripta tus datos a ritmo pausado**  
Puedes usar AWS CLI, scripts, o un Lambda que lea la data e invoque el re-encriptado. Divides tu data y vas re-encriptando “on the fly”.

**4. Depreca la clave antigua**  
Cuando verifiques que ya nada la usa, la retiras (o la marcas para borrado), evitando el riesgo de dejar “herencias” inseguras por ahí.

> **Lo mejor de este método:** Tienes **cero downtime** porque no cambias la clave usada por las aplicaciones de golpe. Y si todo se enreda, regresas al alias anterior y listo.

----------

## Monitoreo de Claves y Recursos Sin Rotar

**¿Cómo saber si alguien sigue usando una clave vieja?**  
Ahora para saber si alguien esta usando una clave vieja propongo estas herramientas y configuraciones:

1.  **AWS Config – KMS_KEY_ROTATION_ENABLED**  
    AWS te provee esta regla. Te notifica cuando detecta una clave sin rotación activada.
    
2.  **AWS Config Aggregator**  
    Si tienes múltiples cuentas y regiones, lo ideal es centralizar los hallazgos. Así no necesitas entrar cuenta por cuenta.
    
3.  **Custom AWS Config Rule**  
    Mediante una Lambda, puedes buscar buckets, tablas, y snapshots que usen una clave con fecha de creación anterior a X meses (o cualquier regla más específica).
    

> Esto es esencial para entornos con requisitos de cumplimiento: ISO, SOC, PCI DSS… En la práctica, tener un panel o reportes de compliance te da paz mental.