
# Scenario #3: Preventing API Gateway Bypass

Al desplegar las APIs detrás de CloudFront y un WAF global para filtrar ataques, todo parece estar bien, pero nos olvidamos que si alguien conoce la URL específica del API Gateway regional, **puede saltarse** CloudFront y llegar directo, evitando así las reglas del WAF. Para abordar ello planteo las siguientes opciones:

----------

## Opción 1: **Bloquear con Resource Policy** (Whitelisting)

En AWS API Gateway, puedes configurar una **API Resource Policy** que deniegue cualquier petición que **no venga** de un VPC Endpoint determinado.Ejemplo: apigw_policy.tf

-   Impone una política que dice: “Solo permito tráfico cuyo origen sea mi VPC Endpoint privado”.
    
-   Si alguien descubre la URL directa de tu API Gateway y la invoca desde fuera de ese endpoint, AWS rechazará la llamada (status 403, ‘Access Denied’).

## Opción 2: **Custom Authorizer + Mutual TLS**

Hay organizaciones que prefieren añadir **mTLS** (mutual TLS) para asegurarse de que el cliente también presenta un certificado válido. Además, se puede implementar un **Lambda authorizer** que revise un token, cabecera o certificado:

1.  **mTLS:**
    
    -   Requieres un certificado de cliente. El servidor (API GW) y el cliente se validan mutuamente.
        
    -   Si alguien intenta conectar sin un cert autorizado, no podrá establecer sesión.
        
2.  **Lambda Authorizer:**
    
    -   Intercepta las llamadas antes de llegar a tu backend.
        
    -   Puedes programarlo para chequear que un encabezado (inserto por CloudFront o WAF) esté presente y sea válido. Si no existe, la petición se bloquea.
        

> A veces conviene combinar ambos enfoques para una estrategia de “defense in depth”: tienes la Resource Policy que cierra cualquier acceso “por la libre”, **y** un Lambda Authorizer con mTLS que añade otro candado más si alguien logra colarse por otro camino.