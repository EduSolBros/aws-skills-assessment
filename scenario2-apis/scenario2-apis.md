
# Scenario #2: APIs-as-a-Product (Internal-External)

Hoy en día, todas las empresas desean exponer APIs de forma segura. El reto viene cuando un mismo conjunto de microservicios sirve tanto a clientes internos (dentro de la empresa) como a externos (clientes, socios, brokers...). Aquí es donde nos topamos con distintos modelos de despliegue y varias estrategias de protección.

----------

## **Por qué la arquitectura actual es débil**

1.  **Todas las APIs son públicas**  
    Esto incrementa la superficie de ataque. Cualquier endpoint “expuesto” es susceptible de recibir tráfico malicioso, escaneos, etc.
    
2.  **El tráfico interno hace un viaje largo**  
    Los servidores dentro de la misma organización tienen que salir por Internet, pasar por CloudFront y volver a AWS. Hay más latencia y, francamente, es algo innecesario si los clientes y la API están dentro del mismo entorno de VPC.
    
3.  **Un solo dominio para todo**  
    Dificulta la aplicación de políticas granulares. No siempre se necesitan las mismas restricciones de seguridad, ni la misma configuración de caching, para una API interna y otra expuesta al mundo.
    

----------

## **Option A: Dos API Gateways separados**

1.  **APIs internas**  
    Creas un _Private API Gateway_ dentro de la VPC. Así, el tráfico interno se queda en la red interna, sin exponerse a Internet.
    
2.  **APIs externas**  
    Sigues con un _API Gateway público_, pero lo pones detrás de CloudFront, WAF y Shield Advanced para protegerte de ataques volumétricos o de capa 7.
    
3.  **DNS**
    
    -   `internal-api.example.com` se resuelve a una _Route 53 Private Hosted Zone_, que apunta al endpoint privado del API Gateway.
        
    -   `api.example.com` se resuelve a tu CloudFront distribution, que luego enruta hacia el _API Gateway público_.
        

> **Ventaja clara:** para las grandes organizaciones, tener entornos separados da orden y evita confusiones. Cada equipo sabe cuáles endpoints se exponen al exterior y cuáles están restringidos a la red interna.

----------

## **Option B: Un solo API Gateway pero con múltiples dominios**

1.  **Define dos dominios**
    
    -   `internal-api.example.com` con tipo de endpoint PRIVATE
        
    -   `api.example.com` con tipo de endpoint REGIONAL + CloudFront
        
2.  **Mapea distintos stages o bases de ruta**  
    Cada dominio apunta a una configuración interna del mismo API Gateway, separando lógicamente el tráfico interno y externo.
    

> **Mi experiencia:** Para empresas pequeñas o medianas, tener un solo API Gateway puede ser más fácil de administrar (menos recursos y configuraciones). Pero si tu organización ya está grande, Option A puede ser más limpio y escalable.


## **Enrutamiento basado en rutas con CloudFront**

Algunos equipos quieren un único “frontdoor” (`api.example.com`) y que CloudFront derive las rutas. Ejemplo: apis_architecture.tf


-   **Path patterns** permiten decir: “Si la URL va a `/v2/*`, lo mando a un API Gateway X; si va a `/v3/*`, lo envío a otro”.
    
-   **HTTPS_ONLY** garantiza cifrado en tránsito.
    
-   Puedes añadir _cache behaviors_ más finos (controlar TTLs, custom headers, etc.).