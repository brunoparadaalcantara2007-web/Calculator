
-- ============================================================
-- CALCULUS TOOLKIT - EXAMEN (UNIFICADO)
-- Menu principal con 5 opciones:
--   1,2,4: formularios numericos con formulas cerradas verificadas
--   3,5:   calculadora general de integral doble (usa CAS real
--          via math.eval; NO usa math.evalStr, no existe en este
--          entorno)
-- ============================================================

platform.apiLevel = '1.0'

-- Variables de zoom y pan para graficos (deben declararse ANTES
-- de dibujarRegion y dibujarRegionPolar que las usan)
local grafZoom = 1.0   -- factor de zoom (1=normal, 2=acerca, 0.5=aleja)
local grafPanX = 0.0   -- desplazamiento horizontal del centro
local grafPanY = 0.0   -- desplazamiento vertical del centro
local grafRotX = 0.5   -- rotacion en eje X para grafica 3D
local grafRotZ = 0.8   -- rotacion en eje Z para grafica 3D

-- ------------------------------------------------------------
-- Formateo de numeros: fraccion simple si es "bonita", si no
-- decimal con varias cifras.
-- ------------------------------------------------------------
local function fmt(n)
    if n == nil then return "?" end
    if n ~= n then return "indefinido" end
    if n == math.huge or n == -math.huge then return "infinito" end
    for den = 1, 1000 do
        local num = n * den
        if math.abs(num - math.floor(num+0.5)) < 1e-6 then
            num = math.floor(num+0.5)
            if den == 1 then
                return tostring(num)
            else
                local function gcd(a,b) a=math.abs(a) b=math.abs(b)
                    while b~=0 do a,b=b,a%b end return a end
                local g = gcd(num,den)
                if g==0 then g=1 end
                return tostring(math.floor(num/g)).."/"..tostring(math.floor(den/g))
            end
        end
    end
    return string.format("%.6f", n)
end

-- ------------------------------------------------------------
-- Formateo simbolico: reconoce constantes matematicas famosas
-- y las muestra en forma exacta en vez de decimal.
-- ------------------------------------------------------------
local function fmtSim(n)
    if n == nil then return "?" end
    if n ~= n then return "indefinido" end
    local e   = math.exp(1)
    local pi  = math.pi
    local ln2 = math.log(2)
    local ln3 = math.log(3)
    local tol = 1e-5

    -- Tabla de constantes conocidas (valor, nombre simbolico)
    -- ORDEN IMPORTA: poner primero las mas especificas/compuestas
    local constantes = {
        -- Expresiones con e y logaritmos (primero las compuestas)
        {6*e^2 - 74/3,      "6*e^2 - 74/3"},
        {2*(e-1),           "2*(e-1)"},
        {2*(e+1),           "2*(e+1)"},
        {(e^2-1)/2,         "(e^2-1)/2"},
        {e^2 - 1,           "e^2 - 1"},
        {2 - ln3/2,         "2 - ln(3)/2"},
        {2 - ln2/2,         "2 - ln(2)/2"},
        {1 - ln2,           "1 - ln(2)"},
        {(e-1)/2,           "(e-1)/2"},
        {e/2 - 1,           "e/2 - 1"},
        {e - 1,             "e - 1"},
        {e/2,               "e/2"},
        {ln3/2,             "ln(3)/2"},
        {ln2/2,             "ln(2)/2"},
        {ln3,               "ln(3)"},
        {ln2,               "ln(2)"},
        {e,                 "e"},
        -- Multiplos de pi (de mayor a menor para evitar falsos matches)
        {81*pi/2,           "81*pi/2"},
        {45*pi/2,           "45*pi/2"},
        {18*pi,             "18*pi"},
        {16*pi/3,           "16*pi/3"},
        {8*pi,              "8*pi"},
        {4*pi,              "4*pi"},
        {3*pi/2,            "3*pi/2"},
        {9*pi/8,            "9*pi/8"},
        {4*pi/3,            "4*pi/3"},
        {2*pi/3,            "2*pi/3"},
        {3*pi/8,            "3*pi/8"},
        {3*pi/4,            "3*pi/4"},
        {2*pi,              "2*pi"},
        {pi,                "pi"},
        {pi/2,              "pi/2"},
        {pi/3,              "pi/3"},
        {pi/4,              "pi/4"},
        {pi/6,              "pi/6"},
        {pi/8,              "pi/8"},
        {pi/12,             "pi/12"},
        -- Con sin/cos
        {20*math.sin(8)/3,  "(20/3)*sin(8)"},
        -- Raices cuadradas
        {2*math.sqrt(3),    "2*sqrt(3)"},
        {math.sqrt(3)/2,    "sqrt(3)/2"},
        {math.sqrt(2)/2,    "sqrt(2)/2"},
        {math.sqrt(3),      "sqrt(3)"},
        {math.sqrt(2),      "sqrt(2)"},
    }

    -- Match exacto (positivo y negativo)
    for _, par in ipairs(constantes) do
        local val, nombre = par[1], par[2]
        if math.abs(n - val) < tol then return nombre end
        if math.abs(n + val) < tol then return "-("..nombre..")" end
    end

    -- Si no es constante conocida, intentar fraccion racional
    return fmt(n)
end


local function calc(expr)
    local ok, r, e = pcall(math.eval, expr, true)
    if ok and type(r) == "number" then return r, nil end

    local ok2, r2, e2 = pcall(math.eval, expr, false)
    if ok2 and type(r2) == "number" then return r2, nil end

    if not ok then return nil, "fallo lua: " .. tostring(r) end
    if not ok2 then return nil, "fallo lua (aprox): " .. tostring(r2) end
    return nil, "CAS no pudo evaluar (err=" .. tostring(e2 or e) .. "): " .. expr
end

-- ============================================================
-- MENU PRINCIPAL
-- ============================================================
local menu = {
    "1. Sombra en la pared",
    "2. Cilindro en esfera",
    "3. Integral doble (general)",
    "4. Volumen entre paraboloides",
    "5. Cambio orden integracion",
    "6. Volumen (coord. polares/cilindr.)",
    "7. Integral doble cartesiana libre",
}

-- ============================================================
-- PROBLEMAS TIPO FORMULARIO NUMERICO (1, 2, 4)
-- ============================================================
local problemasNum = {}

problemasNum[1] = {
    campos = {
        {nombre="Altura persona H (m)", default="1.7"},
        {nombre="Velocidad v (m/s)",    default="1.2"},
        {nombre="Distancia lampara-pared D (m)", default="12"},
        {nombre="Posicion x0 a evaluar (m)", default="4"},
    },
    resolver = function(v)
        local H, vel, D, x0 = tonumber(v[1]), tonumber(v[2]), tonumber(v[3]), tonumber(v[4])
        local L = {}
        local add = function(s) table.insert(L, s) end
        if not (H and vel and D and x0) then
            return "Revisa que todos los campos sean numeros validos."
        end
        if x0 >= D then
            return "Error: x0 debe ser menor que D (la persona\ntodavia no llega a la pared)."
        end

        add("Datos: H="..H.." m, v="..vel.." m/s")
        add("D="..D.." m, evaluar en x="..x0.." m")
        add("")
        add("Paso 1) Semejanza de triangulos:")
        add("h(x)/D = H/(D-x)")
        add("h(x) = D*H/(D-x)")
        add("h(x) = ("..D..")*("..H..")/("..D.."-x)")
        add("")
        add("Paso 2) Derivar respecto a x:")
        add("dh/dx = D*H/(D-x)^2")
        add("")
        add("Paso 3) Regla de la cadena (dx/dt=-v):")
        add("dh/dt = (dh/dx)*(-v) = -D*H*v/(D-x)^2")
        add("")
        add("Paso 4) Sustituir valores en x="..x0..":")
        local denom = (D-x0)^2
        local val = -D*H*vel/denom
        add("dh/dt = -"..fmt(D*H*vel).." / "..fmt(denom))
        add("dh/dt = " .. fmt(val) .. " m/s")
        add("")
        if val < 0 then add("RESPUESTA: la sombra DISMINUYE")
        else add("RESPUESTA: la sombra AUMENTA") end
        add("a razon de " .. fmt(math.abs(val)) .. " m/s")
        return table.concat(L, "\n")
    end
}

problemasNum[2] = {
    campos = {
        {nombre="Radio de la esfera R (cm)", default="6"},
    },
    resolver = function(v)
        local R = tonumber(v[1])
        local L = {}
        local add = function(s) table.insert(L, s) end
        if not R or R<=0 then return "Ingresa un radio R positivo." end

        add("Datos: esfera de radio R="..R.." cm")
        add("")
        add("Paso 1) r^2 + (h/2)^2 = R^2")
        add("")
        add("Paso 2) V(h) = pi*(R^2-h^2/4)*h")
        add("")
        add("Paso 3) dV/dh=0 => h = 2*R/sqrt(3)")
        add("")
        add("Paso 4) V''(h)<0 para h>0 => MAXIMO")
        add("")
        local hopt = 2*math.sqrt(3)*R/3
        local ropt = math.sqrt(6)*R/3
        local Vmax = 4*math.sqrt(3)*math.pi*R^3/9
        add("Paso 5) Sustituir R="..R..":")
        add("h = 2*sqrt(3)*R/3 ≈ " .. string.format("%.4f",hopt) .. " cm")
        add("r = sqrt(6)*R/3 ≈ " .. string.format("%.4f",ropt) .. " cm")
        add("V_max = 4*sqrt(3)*pi*R^3/9 ≈ " .. string.format("%.4f",Vmax) .. " cm^3")
        add("")
        add("RESPUESTA: h≈"..string.format("%.4f",hopt).." cm")
        add("r≈"..string.format("%.4f",ropt).." cm")
        add("V_max≈"..string.format("%.4f",Vmax).." cm^3")
        return table.concat(L, "\n")
    end
}

problemasNum[4] = {
    campos = {
        {nombre="z = A - x^2 - y^2  (valor de A)", default="8"},
        {nombre="z = B(x^2+y^2)-C  (valor de B)", default="3"},
        {nombre="z = B(x^2+y^2)-C  (valor de C)", default="4"},
    },
    resolver = function(v)
        local A, B, C = tonumber(v[1]), tonumber(v[2]), tonumber(v[3])
        local L = {}
        local add = function(s) table.insert(L, s) end
        if not (A and B and C) then return "Revisa que los datos sean numeros validos." end
        if B+1 <= 0 then return "Caso no valido: B+1 debe ser positivo." end

        add("Superficies:")
        add("z = "..A.."-x^2-y^2")
        add("z = "..B.."*(x^2+y^2)-"..C)
        add("")
        add("Paso 1) Curva de interseccion:")
        local r2 = (A+C)/(B+1)
        add("x^2+y^2 = (A+C)/(B+1) = "..fmt(r2))
        local radio = math.sqrt(r2)
        local zval = A - r2
        add("radio = "..string.format("%.4f",radio).."  z="..fmt(zval))
        add("")
        add("a) Orden dz dy dx:")
        add("x: -"..string.format("%.4f",radio).." a "..string.format("%.4f",radio))
        add("y: -sqrt("..fmt(r2).."-x^2) a sqrt("..fmt(r2).."-x^2)")
        add("z: "..B.."(x^2+y^2)-"..C.."  a  "..A.."-x^2-y^2")
        add("")
        add("b) Orden dx dz dy:")
        add("y: -"..string.format("%.4f",radio).." a "..string.format("%.4f",radio))
        add("z: "..B.."*y^2-"..C.."  a  "..A.."-y^2")
        add("x=+/-sqrt("..A.."-z-y^2) o +/-sqrt((z+"..C..")/"..B.."-y^2)")
        add("(segun la superficie que acote en cada tramo)")
        return table.concat(L, "\n")
    end
}

-- ============================================================
-- INTEGRAL DOBLE GENERAL (problemas 3 y 5)
-- ============================================================
local campos = {
    {nombre="f(x,y) =", valor=""},
    {nombre="x: a =", valor=""},
    {nombre="x: b =", valor=""},
    {nombre="y inf(x) =", valor=""},
    {nombre="y sup(x) =", valor=""},
}
local campoActual = 1
local modoGrafica = false
local ordenInt = "dy_dx"  -- "dy_dx" o "dx_dy": orden de integracion

local function cargarCampos(f,a,b,yi,ys)
    campos[1].valor=f campos[2].valor=a campos[3].valor=b
    campos[4].valor=yi campos[5].valor=ys
end

-- ============================================================
-- PRESETS: ejemplos verificados matematicamente con sympy
-- Presiona Tab en el formulario para ciclarlos
-- ============================================================
local presets = {
    -- Indice 1: vacio (para limpiar y escribir lo que quieras)
    {nom="(vacio)", f="", a="", b="", yi="", ys="", orden="dy_dx"},

    -- Indice 2: Ejercicio 3 del examen
    {nom="Ej.3 examen: 5x^3 cos(y^3)",
     f="5*x^3*cos(y^3)", a="0", b="2*sqrt(2)", yi="x^2/4", ys="2", orden="dy_dx"},

    -- Indice 3: Ejercicio 5 del examen (cambiado de orden dx dy)
    -- y es la variable EXTERNA (0 a sqrt(2)), x es la INTERNA (y^2 a 4-y^2)
    {nom="Ej.5 examen: x^2 y exp(y^2) (dx dy)",
     f="x^2*y*exp(y^2)", a="0", b="sqrt(2)", yi="y^2", ys="4-y^2", orden="dx_dy"},

    -- Indice 4: Como el Ej.3 pero con SENO en vez de coseno
    {nom="Como Ej.3 pero sin(y^3)",
     f="5*x^3*sin(y^3)", a="0", b="2*sqrt(2)", yi="x^2/4", ys="2", orden="dy_dx"},

    -- Indice 5: Region triangular simple
    {nom="sin(x+y) region triangular",
     f="sin(x+y)", a="0", b="1", yi="0", ys="1-x", orden="dy_dx"},

    -- Indice 6: Producto sin(x)*cos(y) en cuadrado [0,pi/2]^2
    {nom="sin(x)*cos(y) cuadrado [0,pi/2]",
     f="sin(x)*cos(y)", a="0", b="pi/2", yi="0", ys="pi/2", orden="dy_dx"},

    -- Indice 7: Polinomio x^2*y^2 region bajo la diagonal
    {nom="x^2*y^2 bajo la diagonal y=x",
     f="x^2*y^2", a="0", b="1", yi="0", ys="x", orden="dy_dx"},

    -- Indice 8: Exponencial region triangular
    {nom="y*exp(x) region triangular",
     f="y*exp(x)", a="0", b="1", yi="0", ys="x", orden="dy_dx"},

    -- Indice 9: Region circular primer cuadrante
    {nom="x^2+y^2 cuarto circulo r=1",
     f="x^2+y^2", a="0", b="1", yi="0", ys="sqrt(1-x^2)", orden="dy_dx"},

    -- Indice 10: Integral de Fresnel (cambiando orden)
    {nom="y*sin(y^2) (cambio de orden)",
     f="y*sin(y^2)", a="0", b="1", yi="0", ys="sqrt(x)", orden="dy_dx"},

    -- Indice 11: Raiz cuadrada region parabolica
    {nom="sqrt(x)*y region parabolica",
     f="sqrt(x)*y", a="0", b="4", yi="0", ys="sqrt(x)", orden="dy_dx"},
}
local presetIdx = 1

-- ============================================================
-- PROCEDIMIENTOS COMPLETOS VERIFICADOS (para los 2 ejercicios
-- del examen que tienen desarrollo extenso tipo libro)
-- ============================================================
local function procedimientoEj3()
    local L = {}
    local add = function(s) table.insert(L, s) end
    add("Region: y=2, y=x^2/4, x=0")
    add("")
    add("De: y=x^2/4  =>  x=2*sqrt(y)")
    add("Limites: 0<=y<=2,  0<=x<=2*sqrt(y)")
    add("")
    add("∫∫_D 5x^3 cos(y^3) dA")
    add("= ∫(0,2) ∫(0,2√y) 5x^3 cos(y^3) dx dy")
    add("")
    add("Integrando en x:")
    add("= ∫(0,2) [5x^4/4 cos(y^3)](0,2√y) dy")
    add("= ∫(0,2) 20*y^2*cos(y^3) dy")
    add("")
    add("Sustitucion: u=y^3, du=3y^2 dy")
    add("Cuando y=0: u=0; y=2: u=8")
    add("= (20/3) ∫(0,8) cos(u) du")
    add("= (20/3) [sin(u)](0,8)")
    add("")
    add("RESULTADO EXACTO: (20/3)*sin(8)")
    return L
end

local function procedimientoEj5cambiado()
    local L = {}
    local add = function(s) table.insert(L, s) end
    add("Integral original (dy dx):")
    add("I1: x:0->2, y:0->√x")
    add("I2: x:2->4, y:0->√(4-x)")
    add("")
    add("Region I1: y^2<=x<=2, y>=0")
    add("Region I2: y^2<=4-x, x>=2, y>=0")
    add("")
    add("Despejando x:")
    add("I1: x de y^2 a 2")
    add("I2: x de 2 a 4-y^2")
    add("Union: x de y^2 a 4-y^2")
    add("Rango y: 0 a √2")
    add("")
    add("Orden dx dy:")
    add("∫(0,√2) ∫(y^2,4-y^2) x^2 y e^(y^2) dx dy")
    add("")
    add("Integrando en x:")
    add("[x^3/3 * y e^(y^2)](y^2,4-y^2)")
    add("= y*((4-y^2)^3-y^6)*e^(y^2)/3")
    add("")
    add("RESULTADO EXACTO: 6e^2 - 74/3")
    return L
end

-- ============================================================
-- DETECCION DE PRESET CONOCIDO DEL EXAMEN
-- ============================================================
local function detectarPreset()
    local f,a,b,yi,ys = campos[1].valor,campos[2].valor,
                         campos[3].valor,campos[4].valor,campos[5].valor
    if f=="5*x^3*cos(y^3)" and a=="0" and b=="2*sqrt(2)"
       and yi=="x^2/4" and ys=="2" then return "ej3" end
    if f=="x^2*y*exp(y^2)" and a=="0" and b=="sqrt(2)"
       and yi=="x^2" and ys=="4-x^2" then return "ej5" end
    return nil
end

-- ============================================================
-- EVALUACION DE INTEGRAL DOBLE
-- ============================================================
local function evaluarIntegral()
    local L = {}
    local add = function(s) table.insert(L, s) end
    local f,a,b,yi,ys = campos[1].valor,campos[2].valor,
                         campos[3].valor,campos[4].valor,campos[5].valor

    if f=="" or a=="" or b=="" or yi=="" or ys=="" then
        add("Faltan campos por completar.")
        return L
    end

    local preset = detectarPreset()
    if preset == "ej3" then
        L = procedimientoEj3()
    elseif preset == "ej5" then
        L = procedimientoEj5cambiado()
    else
        -- Procedimiento generico con deteccion de separabilidad
        local aNum = calc(a)
        local bNum = calc(b)

        local ordenTexto = ordenInt=="dy_dx" and "dy dx" or "dx dy"
        add("Integral doble (orden "..ordenTexto.."):")
        if ordenInt == "dy_dx" then
            add("∫("..a..","..b..") ∫("..yi..","..ys..")")
            add("   "..f.." dy dx")
        else
            add("∫("..a..","..b..") ∫("..yi..","..ys..")")
            add("   "..f.." dx dy")
        end
        add("")
        add("Region:")
        if ordenInt == "dy_dx" then
            if aNum and bNum then
                add("x : "..fmt(aNum).." hasta "..fmt(bNum))
            else add("x : "..a.." hasta "..b) end
            add("y : "..yi.." hasta "..ys)
        else
            if aNum and bNum then
                add("y : "..fmt(aNum).." hasta "..fmt(bNum))
            else add("y : "..a.." hasta "..b) end
            add("x : "..yi.." hasta "..ys)
        end
        add("")

        -- Detectar separabilidad: f(x,y) = g(x)*h(y)?
        -- Evaluamos en 4 puntos y verificamos el criterio de ratio constante
        local x1, x2 = 1.0, 2.0
        local y1v, y2v = 0.5, 1.5
        -- Usar puntos del dominio real si disponibles
        if aNum and bNum and bNum > aNum then
            x1 = aNum + (bNum-aNum)*0.3
            x2 = aNum + (bNum-aNum)*0.7
        end
        local function evalF(xv, yv)
            return calc("("..f..")|x="..tostring(xv).."|y="..tostring(yv))
        end
        local f11 = evalF(x1, y1v)
        local f12 = evalF(x1, y2v)
        local f21 = evalF(x2, y1v)
        local f22 = evalF(x2, y2v)

        local esSeparable = false
        if f11 and f12 and f21 and f22 and
           math.abs(f11) > 1e-10 and math.abs(f12) > 1e-10 then
            esSeparable = math.abs(f21/f11 - f22/f12) < 1e-4
        end

        add("Paso 1) Integral interna (en y):")
        add("∫("..yi..","..ys..") ("..f..") dy")
        add("")

        if esSeparable then
            -- f = g(x)*h(y): g(x) sale como constante
            add("Nota: f(x,y) es separable en x e y.")
            add("Tomamos g(x) como constante respecto a y:")
            add("= g(x) * ∫("..yi..","..ys..") h(y) dy")
            add("")
            -- Mostrar el resultado de la integral interna en varios puntos
            add("Valores de la integral interna g(x):")
        else
            add("Integrando en y (x actua como constante):")
        end

        -- Evaluar integral interna en 3 puntos
        local puntos = {}
        if aNum and bNum then
            puntos = {aNum, (aNum+bNum)/2, bNum}
        else
            puntos = {x1, (x1+x2)/2, x2}
        end
        local etiq = {"a", "medio", "b"}
        for k=1,3 do
            local xv = puntos[k]
            local exprInterna = "integral("..f..",y,"..yi..","..ys..")|x="..tostring(xv)
            local v = calc(exprInterna)
            if v then
                add("  x="..fmt(xv)..": g(x)="..fmtSim(v))
            end
        end
        add("")
        add("Paso 2) Integral externa (en x):")
        add("∫("..a..","..b..") g(x) dx")
        add("")
    end

    -- Calcular resultado final con CAS segun el orden de integracion
    local exprTotal
    if ordenInt == "dy_dx" then
        -- Orden dy dx: integral interna en y, externa en x
        exprTotal = "integral((integral("..f..",y,"
                    ..yi..","..ys.."))"..",x,"..a..","..b..")"
    else
        -- Orden dx dy: integral interna en x, externa en y
        -- Los campos contienen: a,b = limites de y; yi,ys = limites de x
        exprTotal = "integral((integral("..f..",x,"
                    ..yi..","..ys.."))"..",y,"..a..","..b..")"
    end
    local total, errTotal = calc(exprTotal)

    add("")
    if not total then
        add("CAS no pudo evaluar:")
        add(tostring(errTotal))
        add("")
        add("--- SINTAXIS CORRECTA ---")
        add("Multiplicar: x*y  (no: xy)")
        add("Potencia:    x^2  (no: x2)")
        add("Exponencial: exp(x)  <- CORRECTO")
        add("             e^(x)   <- NO funciona")
        add("Raiz:        sqrt(x)")
        add("Seno:        sin(x), cos(x)")
        add("Pi:          pi")
        add("")
        add("Ejemplos: sin(x)*cos(y), exp(x)*y")
        add("          sqrt(x)*y, x^2*y^2")
    else
        add("Paso 3) Resultado final:")
        add("")
        add("RESULTADO: " .. fmtSim(total))
    end
    return L
end

local function evaluarEnVar(expr, varNombre, val)
    -- Sustituye varNombre por val en expr y evalua con el CAS
    local r = calc("("..expr..")|"..varNombre.."="..tostring(val))
    if r then return r end
    -- Fallback: reemplazo de texto
    local e2 = expr:gsub(varNombre, "("..tostring(val)..")")
    return calc(e2)
end

-- Mantener evaluarEnX por compatibilidad con codigo existente
local function evaluarEnX(expr, xval)
    return evaluarEnVar(expr, "x", xval)
end

local function dibujarRegion(gc, w, h)
    local a = calc(campos[2].valor) or 0
    local b = calc(campos[3].valor) or 0
    if b <= a then gc:drawString("Limites invalidos para graficar", 10, 40, "top") return end

    -- Variable de barrido: x en dy_dx, y en dx_dy
    local varBarrido = (ordenInt == "dy_dx") and "x" or "y"
    local varInterna = (ordenInt == "dy_dx") and "y" or "x"

    local N = 30
    local pts_inf, pts_sup = {}, {}
    local ymin, ymax = math.huge, -math.huge
    for i=0,N do
        local tv = a + (b-a)*i/N  -- valor de la variable de barrido
        local vi = evaluarEnVar(campos[4].valor, varBarrido, tv)
        local vs = evaluarEnVar(campos[5].valor, varBarrido, tv)
        pts_inf[i] = vi
        pts_sup[i] = vs
        if vi then ymin=math.min(ymin,vi) ymax=math.max(ymax,vi) end
        if vs then ymin=math.min(ymin,vs) ymax=math.max(ymax,vs) end
    end
    if ymin==math.huge then
        gc:drawString("No se pudo evaluar la region", 10, 40, "top")
        gc:drawString("("..varBarrido.." externo, "..varInterna.." interno)", 10, 56, "top")
        return
    end

    -- Rango base (incluye origen)
    local xMin0, xMax0 = math.min(a,0), math.max(b,0)
    local yMin0, yMax0 = math.min(ymin,0), math.max(ymax,0)
    local xPad = (xMax0-xMin0)*0.15; if xPad==0 then xPad=1 end
    local yPad = (yMax0-yMin0)*0.15; if yPad==0 then yPad=1 end
    xMin0, xMax0 = xMin0-xPad, xMax0+xPad
    yMin0, yMax0 = yMin0-yPad, yMax0+yPad

    -- Aplicar zoom y pan
    local cx = (xMin0+xMax0)/2 + grafPanX
    local cy = (yMin0+yMax0)/2 + grafPanY
    local rx = (xMax0-xMin0)/(2*grafZoom)
    local ry = (yMax0-yMin0)/(2*grafZoom)
    local xMin, xMax = cx-rx, cx+rx
    local yMin, yMax = cy-ry, cy+ry

    local margin = 16
    -- Dejar espacio para los controles en la parte de abajo
    local plotH_total = h - margin - 22  -- 22px para la barra de controles
    local plotW = w-2*margin
    local function toPx(xv) return margin + (xv-xMin)/(xMax-xMin)*plotW end
    local function toPy(yv) return (margin+plotH_total) - (yv-yMin)/(yMax-yMin)*plotH_total end

    -- Grilla
    gc:setColorRGB(225,225,225)
    local function niceStep(range)
        if range <= 0 then return 1 end
        local raw = range/6
        local mag = 10^math.floor(math.log(raw)/math.log(10))
        local norm = raw/mag
        local step
        if norm<1.5 then step=1 elseif norm<3.5 then step=2 elseif norm<7.5 then step=5 else step=10 end
        return step*mag
    end
    local stepX, stepY = niceStep(xMax-xMin), niceStep(yMax-yMin)
    local gx = math.ceil(xMin/stepX)*stepX
    while gx <= xMax do
        local px = toPx(gx)
        gc:drawLine(px, margin, px, margin+plotH_total)
        gx=gx+stepX
    end
    local gy = math.ceil(yMin/stepY)*stepY
    while gy <= yMax do
        local py = toPy(gy)
        gc:drawLine(margin, py, w-margin, py)
        gy=gy+stepY
    end

    -- Region sombreada
    gc:setColorRGB(190,210,250)
    for i=0,N-1 do
        if pts_inf[i] and pts_sup[i] and pts_inf[i+1] and pts_sup[i+1] then
            local x1,x2 = toPx(a+(b-a)*i/N), toPx(a+(b-a)*(i+1)/N)
            local yA,yB = toPy(pts_inf[i]), toPy(pts_sup[i])
            gc:fillRect(x1, math.min(yA,yB), math.max(2,x2-x1), math.abs(yA-yB))
        end
    end

    -- Ejes cartesianos
    gc:setColorRGB(60,60,60)
    local ox, oy = toPx(0), toPy(0)
    -- Clampear al area visible
    oy = math.max(margin, math.min(margin+plotH_total, oy))
    ox = math.max(margin, math.min(w-margin, ox))
    gc:drawLine(margin, oy, w-margin, oy)
    gc:drawLine(ox, margin, ox, margin+plotH_total)
    gc:drawLine(w-margin, oy, w-margin-5, oy-3)
    gc:drawLine(w-margin, oy, w-margin-5, oy+3)
    gc:drawLine(ox, margin, ox-3, margin+6)
    gc:drawLine(ox, margin, ox+3, margin+6)
    gc:setFont("sansserif","b",7)
    gc:drawString("+"..varBarrido:upper(), w-margin-14, oy-10, "top")
    gc:drawString("+"..varInterna:upper(), ox+3, margin+1, "top")
    gc:drawString("0",  ox+2, oy+1, "top")
    -- Etiquetas de escala en los ejes
    gc:setFont("sansserif","r",7)
    gc:setColorRGB(80,80,80)
    local gx2 = math.ceil(xMin/stepX)*stepX
    while gx2 <= xMax do
        if math.abs(gx2) > stepX*0.1 then
            gc:drawString(fmt(gx2), toPx(gx2)-8, oy+2, "top")
        end
        gx2=gx2+stepX
    end
    local gy2 = math.ceil(yMin/stepY)*stepY
    while gy2 <= yMax do
        if math.abs(gy2) > stepY*0.1 then
            gc:drawString(fmt(gy2), ox+2, toPy(gy2)-6, "top")
        end
        gy2=gy2+stepY
    end

    -- Curvas de la region
    gc:setColorRGB(0,80,190)
    for i=0,N-1 do
        if pts_sup[i] and pts_sup[i+1] then
            gc:drawLine(toPx(a+(b-a)*i/N), toPy(pts_sup[i]),
                        toPx(a+(b-a)*(i+1)/N), toPy(pts_sup[i+1]))
        end
    end
    gc:setColorRGB(190,0,0)
    for i=0,N-1 do
        if pts_inf[i] and pts_inf[i+1] then
            gc:drawLine(toPx(a+(b-a)*i/N), toPy(pts_inf[i]),
                        toPx(a+(b-a)*(i+1)/N), toPy(pts_inf[i+1]))
        end
    end

    -- Barra de controles en la parte de abajo
    gc:setColorRGB(240,240,240)
    gc:fillRect(0, h-21, w, 21)
    gc:setColorRGB(100,100,100)
    gc:drawLine(0, h-21, w, h-21)
    gc:setFont("sansserif","r",7)
    gc:setColorRGB(0,0,0)
    gc:drawString("+/-=zoom  flechas=pan  R=reset  G=texto", 4, h-18, "top")
    gc:drawString("zoom:"..string.format("%.1f",grafZoom).."x", w-42, h-18, "top")
end

-- ============================================================
-- MODULO 6: VOLUMEN EN COORDENADAS POLARES / CILINDRICAS
-- Campos: f(r,t)=, r_inf=, r_sup=, t_inf=, t_sup=
-- La integral es ∫∫ f(r,t)*r dr dt (el jacobiano r ya se incluye)
-- Presets incluyen los 4 nuevos problemas verificados
-- ============================================================
local camposPol = {
    {nombre="z sup - z inf  (en r, theta)", valor="9-r^2"},
    {nombre="r inferior =",                  valor="0"},
    {nombre="r superior =",                  valor="sqrt(3)"},
    {nombre="theta inferior =",              valor="0"},
    {nombre="theta superior =",              valor="2*pi"},
}
local campoPolarActual = 1
local presetPolIdx = 1

local presetsPol = {
    {nom="(vacio)", f="", ri="", rs="", ti="", ts=""},
    -- P1: z=9-x^2-y^2 sobre x^2+y^2<=3  => f=9-r^2, r:0->sqrt(3), t:0->2*pi
    -- V = 45*pi/2
    {nom="P1: z=9-x^2-y^2, x^2+y^2<=3",
     f="9-r^2", ri="0", rs="sqrt(3)", ti="0", ts="2*pi"},
    -- P2: entre z=x^2+y^2 y z=9  => f=9-r^2, r:0->3, t:0->2*pi
    -- V = 81*pi/2
    {nom="P2: entre z=x^2+y^2 y z=9",
     f="9-r^2", ri="0", rs="3", ti="0", ts="2*pi"},
    -- P3: entre z=x^2+y^2 (abajo) y z=2-x^2-y^2 (arriba)
    -- f=(2-r^2)-r^2=2-2*r^2, r:0->1, t:0->2*pi
    -- V = pi
    {nom="P3: z=2-x^2-y^2 arriba, z=x^2+y^2 abajo",
     f="2-2*r^2", ri="0", rs="1", ti="0", ts="2*pi"},
    -- P4: f(x,y)=x=r*cos(t), region 1er cuadrante y=0, 3x-4y=0 (t=arctan(3/4)), r:0->5
    -- V = 25
    {nom="P4: f=x, region acotada circulo r=5",
     f="r*cos(theta)", ri="0", rs="5", ti="0", ts="arctan(3/4)"},
    -- Extra: volumen bajo z=4-r^2 sobre disco r<=2
    -- V = ∫(0,2pi)∫(0,2)(4-r^2)*r dr dt = 8*pi
    {nom="Extra: z=4-r^2 sobre disco r<=2",
     f="4-r^2", ri="0", rs="2", ti="0", ts="2*pi"},
}

local resultadoPolLineas = {}
local modoGraficaPol = false

local function cargarCamposPol(f,ri,rs,ti,ts)
    camposPol[1].valor=f camposPol[2].valor=ri camposPol[3].valor=rs
    camposPol[4].valor=ti camposPol[5].valor=ts
end

local function evaluarPolar()
    local L = {}
    local add = function(s) table.insert(L, s) end
    local f  = camposPol[1].valor
    local ri = camposPol[2].valor
    local rs = camposPol[3].valor
    local ti = camposPol[4].valor
    local ts = camposPol[5].valor

    if f=="" or ri=="" or rs=="" or ti=="" or ts=="" then
        add("Faltan campos por completar.")
        return L
    end

    -- Detectar si f depende de theta ademas de r
    -- Evaluamos f en (r=1,theta=0.5) y (r=1,theta=1.0)
    -- Si los valores son distintos, f depende de theta
    local fAt05 = calc("("..f..")|r=1|theta=0.5")
    local fAt10 = calc("("..f..")|r=1|theta=1.0")
    local dependeDeTheta = (fAt05 and fAt10 and math.abs(fAt05 - fAt10) > 1e-6)

    -- Calcular el resultado total PRIMERO para mostrarlo al inicio
    local total, err
    if dependeDeTheta then
        -- f depende de theta: usar integral anidada completa
        -- integral(integral(f*r, r, ri, rs), theta, ti, ts)
        -- Como r en f puede conflictuar, usamos sustitucion r->u
        local function rToU(s)
            local out, i = {}, 1
            while i <= #s do
                local c = s:sub(i,i)
                if c=="r" then
                    local prev = i>1 and s:sub(i-1,i-1) or " "
                    local nxt  = i<#s and s:sub(i+1,i+1) or " "
                    if not prev:match("[%a%d]") and not nxt:match("[%a%d_]") then
                        out[#out+1]="u"
                    else out[#out+1]="r" end
                else out[#out+1]=c end
                i=i+1
            end
            return table.concat(out)
        end
        local fu = rToU(f)
        local exprFull = "integral((integral(("..fu..")*u,u,"..rToU(ri)..","..rToU(rs).."))"..",theta,"..ti..","..ts..")"
        total, err = calc(exprFull)
        -- Si falla, intentar sin sustitucion (a veces funciona si el CAS es listo)
        if not total then
            local exprFull2 = "integral((integral(("..f..")*r,r,"..ri..","..rs.."))"..",theta,"..ti..","..ts..")"
            total, err = calc(exprFull2)
        end
    else
        -- f NO depende de theta: separar en dos integrales
        local exprR = "integral(("..f..")*r,r,"..ri..","..rs..")"
        local valR  = calc(exprR)
        local valTh = calc("("..ts..")-("..ti..")")
        if valR and valTh then
            total = valR * valTh
        end
    end

    -- Mostrar resultado al inicio
    add("Integral en coord. polares/cilindr.:")
    if total then
        add(">>> RESULTADO: " .. fmtSim(total) .. " <<<")
    else
        add(">>> CAS no pudo evaluar <<<")
    end
    add("")
    add("V = ∫("..ti..","..ts..") ∫("..ri..","..rs..")")
    add("      ("..f..") * r  dr dtheta")
    add("")
    add("Jacobiano: el factor r multiplica al integrando")
    add("para convertir dA cartesiano a dr dtheta")
    add("")    -- Mostrar resultado al inicio (siempre visible sin scroll)
    if total then
        add(">>> RESULTADO: " .. fmtSim(total) .. " <<<")
    else
        add(">>> CAS no pudo evaluar: "..tostring(err).." <<<")
    end
    add("")

    -- Encabezado de la integral
    add("V = ∫("..ti..","..ts..") ∫("..ri..","..rs..")")
    add("      ("..f..") * r  dr dtheta")
    add("")
    add("Jacobiano: r (ya incluido internamente)")
    add("")

    -- Detectar cual preset es para dar el procedimiento correcto
    local esP1 = (f=="9-r^2" and rs=="sqrt(3)" and ts=="2*pi")
    local esP2 = (f=="9-r^2" and rs=="3" and ts=="2*pi")
    local esP3 = (f=="2-2*r^2" and rs=="1" and ts=="2*pi")
    local esP4 = (f=="r*cos(theta)" and rs=="5" and ts=="arctan(3/4)")

    if esP1 then
        add("Problema: z=9-x^2-y^2 sobre x^2+y^2<=3")
        add("Conversion: x^2+y^2=r^2, z=9-r^2")
        add("Region: r<=sqrt(3)")
        add("")
        add("V = ∫(0,2pi) ∫(0,√3) (9-r^2)*r dr dt")
        add("")
        add("Integral en r:")
        add("∫(0,√3) (9r-r^3) dr")
        add("= [9r^2/2 - r^4/4](0,√3)")
        add("= 27/2 - 9/4 = 45/4")
        add("")
        add("Integral en t:")
        add("∫(0,2pi) 45/4 dt = 45/4 * 2pi")
        add("")
        add("RESULTADO EXACTO: 45*pi/2")
    elseif esP2 then
        add("Problema: solido entre z=x^2+y^2 y z=9")
        add("Interseccion: r^2=9 => r=3")
        add("Altura del solido: 9-r^2")
        add("")
        add("V = ∫(0,2pi) ∫(0,3) (9-r^2)*r dr dt")
        add("")
        add("Integral en r:")
        add("∫(0,3) (9r-r^3) dr")
        add("= [9r^2/2 - r^4/4](0,3)")
        add("= 81/2 - 81/4 = 81/4")
        add("")
        add("Integral en t:")
        add("∫(0,2pi) 81/4 dt = 81*pi/2")
        add("")
        add("Limites orden dz dx dy:")
        add("y: -3 a 3")
        add("x: -sqrt(9-y^2) a sqrt(9-y^2)")
        add("z: x^2+y^2 a 9")
        add("")
        add("RESULTADO EXACTO: 81*pi/2")
    elseif esP3 then
        add("Problema: z=2-x^2-y^2 arriba, z=x^2+y^2 abajo")
        add("Interseccion: 2-r^2=r^2 => r=1")
        add("Altura: (2-r^2)-r^2 = 2-2*r^2")
        add("")
        add("V = ∫(0,2pi) ∫(0,1) (2-2r^2)*r dr dt")
        add("")
        add("Integral en r:")
        add("∫(0,1) (2r-2r^3) dr")
        add("= [r^2 - r^4/2](0,1)")
        add("= 1 - 1/2 = 1/2")
        add("")
        add("Integral en t:")
        add("∫(0,2pi) 1/2 dt = pi")
        add("")
        add("RESULTADO EXACTO: pi")
    elseif esP4 then
        add("Problema: f(x,y)=x, region 1er cuadrante")
        add("Curvas: y=0 (t=0), 3x-4y=0 (t=arctan(3/4))")
        add("        y=√(25-x^2) (circulo r=5)")
        add("")
        add("En polares: f=x=r*cos(theta)")
        add("V = ∫(0,arctan(3/4)) ∫(0,5) r*cos(theta)*r dr dtheta")
        add("  = ∫(0,arctan(3/4)) cos(theta) dtheta * ∫(0,5) r^2 dr")
        add("")
        add("Integral en r: ∫(0,5) r^2 dr = 125/3")
        add("")
        add("Integral en theta: ∫(0,arctan(3/4)) cos(theta) dtheta")
        add("= [sin(theta)](0,arctan(3/4))")
        add("= sin(arctan(3/4)) = 3/5")
        add("")
        add("V = 125/3 * 3/5 = 25")
        add("")
        add("RESULTADO EXACTO: 25")
    else
        -- Procedimiento general con deteccion de dependencia en theta 
        if dependeDeTheta then
            add("Nota: f depende de r Y de theta.")
            add("No se puede separar: integral anidada completa.")
            add("")
            add("Paso 1) Integral interna en r (theta=cte):")
            add("∫("..ri..","..rs..") ("..f..")*r dr")
            add("(el resultado es una funcion de theta)")
            add("")
            add("Paso 2) Integral en theta del resultado:")
            add("∫("..ti..","..ts..") [g(theta)] dtheta")
        else
            add("Nota: f solo depende de r.")
            add("Se puede separar en dos integrales.")
            add("")
            add("Paso 1) Integral interna en r:")
            add("∫("..ri..","..rs..") ("..f..")*r dr")
            local exprRshow = "integral(("..f..")*r,r,"..ri..","..rs..")"
            local vRshow = calc(exprRshow)
            if vRshow then
                add("= " .. fmtSim(vRshow))
            else
                add("(evaluando con el CAS...)")
            end
            add("")
            add("Paso 2) Integral en theta:")
            add("∫("..ti..","..ts..") "..
                (vRshow and fmtSim(vRshow) or "C").." dtheta")
            local vTshow = calc("("..ts..")-("..ti..")")
            if vRshow and vTshow then
                local producto = vRshow * vTshow
                add("= "..fmtSim(vRshow).." * "..fmtSim(vTshow))
                add("= "..fmtSim(producto))
            end
        end
        add("")
        add("Sintaxis: r, theta, sin() cos() sqrt() pi")
    end

    add("")
    return L
end

local function dibujar3D(gc, w, h)
    local a = calc(campos[2].valor)
    local b = calc(campos[3].valor)
    if not a or not b or b <= a then
        gc:drawString("Limites invalidos para grafico 3D", 8, 40, "top")
        return
    end

    local f  = campos[1].valor
    local li = campos[4].valor
    local ls = campos[5].valor
    local varExt = (ordenInt == "dy_dx") and "x" or "y"
    local varInt = (ordenInt == "dy_dx") and "y" or "x"

    local N = 10
    local pts = {}
    local zmin, zmax = math.huge, -math.huge
    local intMin, intMax = math.huge, -math.huge

    for i=0,N do
        pts[i] = {}
        local extV = a + (b-a)*i/N
        local liNum = evaluarEnVar(li, varExt, extV) or 0
        local lsNum = evaluarEnVar(ls, varExt, extV) or liNum+1
        if lsNum <= liNum then lsNum = liNum + 1 end
        intMin = math.min(intMin, liNum)
        intMax = math.max(intMax, lsNum)
        for j=0,N do
            local intV = liNum + (lsNum-liNum)*j/N
            local xv = (ordenInt=="dy_dx") and extV or intV
            local yv = (ordenInt=="dy_dx") and intV or extV
            local zv = calc("("..f..")|x="..tostring(xv).."|y="..tostring(yv))
            if not zv then
                zv = calc("("..f..")|y="..tostring(yv).."|x="..tostring(xv))
            end
            if not zv then
                local fx = f:gsub("x", "("..tostring(xv)..")")
                zv = calc("("..fx..")|y="..tostring(yv))
            end
            if not zv then
                local fy = f:gsub("y", "("..tostring(yv)..")")
                zv = calc("("..fy..")|x="..tostring(xv))
            end
            pts[i][j] = {x=xv, y=yv, z=zv}
            if zv then
                zmin = math.min(zmin, zv)
                zmax = math.max(zmax, zv)
            end
        end
    end

    if zmin == math.huge then
        gc:drawString("No se pudo evaluar la superficie", 8, 40, "top")
        gc:drawString("Verifica sintaxis: * ^ exp() sqrt()", 8, 56, "top")
        return
    end
    if zmax == zmin then zmax = zmin + 1 end
    if intMin == math.huge then intMin = 0 end
    if intMax == -math.huge then intMax = 1 end

    -- Proyeccion isometrica: pantalla (px, py) desde (x, y, z)
    -- Con zoom y pan
    local cx = (a+b)/2
    local cy = (intMin+intMax)/2
    local cz = (zmin+zmax)/2
    local xRange = b - a
    local yRange = intMax - intMin
    local cosZ = math.cos(grafRotZ)
    local sinZ = math.sin(grafRotZ)
    local cosX = math.cos(grafRotX)
    local sinX = math.sin(grafRotX)
    local zRange  = zmax - zmin
    local xyRange = math.max(xRange, yRange, 1)
    local zScale  = math.min(zRange / xyRange, 3.0)
    local sc = math.min(w, h) * 0.25 * grafZoom / xyRange

    local function proj(xv, yv, zv)
        local dx = xv - cx
        local dy = yv - cy
        local dz = (zv - cz) / math.max(zRange, 1) * xyRange * zScale
        local rx =  dx * cosZ + dy * sinZ
        local ry = -dx * sinZ + dy * cosZ
        local fz2 = ry * sinX + dz * cosX
        local px = w/2 + grafPanX * 30 + rx * sc
        local py = h/2 - grafPanY * 30 - fz2 * sc
        local fy2 = ry * cosX - dz * sinX
        return px, py, fy2
    end

    -- Fondo
    gc:setColorRGB(255,255,255)
    gc:fillRect(0,0,w,h-21)

    -- Dibujar la malla de la superficie (lineas en x fijo, luego y fijo)
    -- Color segun altura (azul=bajo, rojo=alto)
    local function colorZ(z)
        if not z then return 128,128,128 end
        local t = (z-zmin)/(zmax-zmin)
        -- degradado azul -> cian -> verde -> amarillo -> rojo
        local r2,g2,b2
        if t < 0.25 then
            local s = t/0.25
            r2=0; g2=math.floor(s*200); b2=255
        elseif t < 0.5 then
            local s = (t-0.25)/0.25
            r2=0; g2=200; b2=math.floor(255*(1-s))
        elseif t < 0.75 then
            local s = (t-0.5)/0.25
            r2=math.floor(s*255); g2=200; b2=0
        else
            local s = (t-0.75)/0.25
            r2=255; g2=math.floor(200*(1-s)); b2=0
        end
        return r2,g2,b2
    end

    -- Dibujar cuadrilateros de la malla (de atras hacia adelante)
    for i=0,N-1 do
        for j=0,N-1 do
            local p00=pts[i][j]; local p10=pts[i+1][j]
            local p01=pts[i][j+1]; local p11=pts[i+1][j+1]
            if p00.z and p10.z and p01.z and p11.z then
                local zmid = (p00.z+p10.z+p01.z+p11.z)/4
                local r2,g2,b2 = colorZ(zmid)
                gc:setColorRGB(r2,g2,b2)
                local x0,y0 = proj(p00.x,p00.y,p00.z)
                local x1,y1 = proj(p10.x,p10.y,p10.z)
                local x2,y2 = proj(p11.x,p11.y,p11.z)
                local x3,y3 = proj(p01.x,p01.y,p01.z)
                -- Rellenar con lineas horizontales del cuadrilatero
                gc:drawLine(x0,y0,x1,y1)
                gc:drawLine(x1,y1,x2,y2)
                gc:drawLine(x2,y2,x3,y3)
                gc:drawLine(x3,y3,x0,y0)
            end
        end
    end

    -- Ejes 3D simples
    -- Eje X (rojo) - variable externa
    gc:setColorRGB(200,0,0)
    local ax0,ay0 = proj(a,    intMin, zmin)
    local ax1,ay1 = proj(b,    intMin, zmin)
    gc:drawLine(math.floor(ax0),math.floor(ay0),math.floor(ax1),math.floor(ay1))
    gc:setFont("sansserif","b",7) gc:setColorRGB(200,0,0)
    gc:drawString(varExt, math.floor(ax1)+3, math.floor(ay1)-4, "top")
    gc:setFont("sansserif","r",6) gc:setColorRGB(150,0,0)
    for k=0,4 do
        local v = a + (b-a)*k/4
        local mx,my = proj(v, intMin, zmin)
        gc:drawLine(math.floor(mx),math.floor(my),math.floor(mx),math.floor(my)+3)
        gc:drawString(string.format("%.1f",v), math.floor(mx)-7, math.floor(my)+4, "top")
    end

    -- Eje Y (verde) - variable interna, extender al maximo real
    local intMaxReal = math.max(intMax,
        (evaluarEnVar(ls, varExt, a) or intMax),
        (evaluarEnVar(ls, varExt, (a+b)/2) or intMax),
        (evaluarEnVar(ls, varExt, b) or intMax))
    gc:setColorRGB(0,140,0)
    local ay0x,ay0y = proj(a, intMin,    zmin)
    local ay1x,ay1y = proj(a, intMaxReal, zmin)
    gc:drawLine(math.floor(ay0x),math.floor(ay0y),math.floor(ay1x),math.floor(ay1y))
    gc:setFont("sansserif","b",7) gc:setColorRGB(0,140,0)
    gc:drawString(varInt, math.floor(ay1x)+3, math.floor(ay1y)-4, "top")
    gc:setFont("sansserif","r",6) gc:setColorRGB(0,100,0)
    for k=0,4 do
        local v = intMin + (intMaxReal-intMin)*k/4
        local mx,my = proj(a, v, zmin)
        gc:drawLine(math.floor(mx),math.floor(my),math.floor(mx)-3,math.floor(my))
        gc:drawString(string.format("%.1f",v), math.floor(mx)-28, math.floor(my)-4, "top")
    end

    -- Eje Z (azul)
    gc:setColorRGB(0,0,200)
    local az0x,az0y = proj(a, intMin, zmin)
    local az1x,az1y = proj(a, intMin, zmax)
    gc:drawLine(math.floor(az0x),math.floor(az0y),math.floor(az1x),math.floor(az1y))
    gc:setFont("sansserif","b",7) gc:setColorRGB(0,0,200)
    gc:drawString("z", math.floor(az1x)-6, math.floor(az1y)-10, "top")
    gc:setFont("sansserif","r",6) gc:setColorRGB(0,0,150)
    for k=0,4 do
        local v = zmin + zRange*k/4
        local mx,my = proj(a, intMin, v)
        gc:drawLine(math.floor(mx),math.floor(my),math.floor(mx)-3,math.floor(my))
        gc:drawString(string.format("%.1f",v), math.floor(mx)-30, math.floor(my)-4, "top")
    end

    -- Info en esquina superior izquierda
    gc:setColorRGB(60,60,60) gc:setFont("sansserif","r",7)
    gc:drawString("f: "..string.format("%.2f",zmin)..
                  " a "..string.format("%.2f",zmax), 4, 20, "top")
    gc:drawString(string.format("rot:%.1f elev:%.1f",
        math.deg(grafRotZ), math.deg(grafRotX)), 4, 30, "top")

    -- Barra de controles
    gc:setColorRGB(240,240,240)
    gc:fillRect(0, h-21, w, 21)
    gc:setColorRGB(100,100,100)
    gc:drawLine(0, h-21, w, h-21)
    gc:setFont("sansserif","r",7)
    gc:setColorRGB(0,0,0)
    gc:drawString("+/-=zoom  flechas=rotar/pan  R=reset  G=2D", 4, h-18, "top")
    gc:drawString("zoom:"..string.format("%.1f",grafZoom).."x", w-42, h-18, "top")
end

local function dibujarRegionPolar(gc, w, h)
    -- Graficar la region en el plano xy (proyeccion)
    local riNum = calc(camposPol[2].valor) or 0
    local rsNum = calc(camposPol[3].valor) or 1
    local tiNum = calc(camposPol[4].valor) or 0
    local tsNum = calc(camposPol[5].valor) or (2*math.pi)
    if not rsNum or not tsNum or not tiNum then
        gc:drawString("No se pudo graficar (revisa limites)", 8, 40, "top")
        return
    end

    local N = 60
    local margin = 18
    local xMax = rsNum * 1.2
    local xMin = -xMax
    local yMax = xMax
    local yMin = -xMax
    local plotW = w-2*margin
    local plotH = h-2*margin
    local function toPx(xv) return margin + (xv-xMin)/(xMax-xMin)*plotW end
    local function toPy(yv) return (h-margin) - (yv-yMin)/(yMax-yMin)*plotH end

    -- grilla
    gc:setColorRGB(225,225,225)
    for gv = -4, 4 do
        gc:drawLine(toPx(gv), margin, toPx(gv), h-margin)
        gc:drawLine(margin, toPy(gv), w-margin, toPy(gv))
    end

    -- region sombreada
    gc:setColorRGB(190,210,250)
    for i=0,N-1 do
        local t1 = tiNum + (tsNum-tiNum)*i/N
        local t2 = tiNum + (tsNum-tiNum)*(i+1)/N
        for j=0,N-1 do
            local r1 = riNum + (rsNum-riNum)*j/N
            local r2 = riNum + (rsNum-riNum)*(j+1)/N
            local cx = ((r1+r2)/2) * math.cos((t1+t2)/2)
            local cy = ((r1+r2)/2) * math.sin((t1+t2)/2)
            local sz = (rsNum-riNum)/N * (tsNum-tiNum)/N * ((r1+r2)/2) * plotW/(xMax-xMin)
            sz = math.max(2, sz*15)
            gc:fillRect(toPx(cx)-sz/2, toPy(cy)-sz/2, sz, sz)
        end
    end

    -- ejes
    gc:setColorRGB(60,60,60)
    local ox, oy = toPx(0), toPy(0)
    gc:drawLine(margin, oy, w-margin, oy)
    gc:drawLine(ox, margin, ox, h-margin)
    gc:drawLine(w-margin, oy, w-margin-6, oy-3)
    gc:drawLine(w-margin, oy, w-margin-6, oy+3)
    gc:drawLine(ox, margin, ox-3, margin+6)
    gc:drawLine(ox, margin, ox+3, margin+6)
    gc:setFont("sansserif","b",8)
    gc:drawString("+X", w-margin-16, oy-12, "top")
    gc:drawString("+Y", ox+4, margin, "top")
    gc:drawString("0", ox+3, oy+2, "top")

    -- borde de la region (arcos y radios) 
    gc:setColorRGB(0,80,190)
    for i=0,N-1 do
        local t1 = tiNum + (tsNum-tiNum)*i/N
        local t2 = tiNum + (tsNum-tiNum)*(i+1)/N
        gc:drawLine(toPx(rsNum*math.cos(t1)), toPy(rsNum*math.sin(t1)),
                    toPx(rsNum*math.cos(t2)), toPy(rsNum*math.sin(t2)))
        if riNum > 0 then
            gc:drawLine(toPx(riNum*math.cos(t1)), toPy(riNum*math.sin(t1)),
                        toPx(riNum*math.cos(t2)), toPy(riNum*math.sin(t2)))
        end
    end
    gc:setColorRGB(190,0,0)
    gc:drawLine(toPx(riNum*math.cos(tiNum)), toPy(riNum*math.sin(tiNum)),
                toPx(rsNum*math.cos(tiNum)), toPy(rsNum*math.sin(tiNum)))
    gc:drawLine(toPx(riNum*math.cos(tsNum)), toPy(riNum*math.sin(tsNum)),
                toPx(rsNum*math.cos(tsNum)), toPy(rsNum*math.sin(tsNum)))

    gc:setFont("sansserif","r",7)
    gc:setColorRGB(0,80,190) gc:drawString("azul: arcos r", margin+4, margin+2, "top")
    gc:setColorRGB(190,0,0)  gc:drawString("rojo: radios t", margin+4, margin+13, "top")
end

-- ============================================================
-- ESTADO GLOBAL DE NAVEGACION
-- ============================================================
-- pantalla: "menu"|"form_num"|"resultado_num"|"form_int"|"resultado_int"|"form_pol"|"resultado_pol"
local pantalla = "menu"
local seleccion = 1

local campoNumActual = 1
local valoresNum = {}

-- Variables de zoom y pan declaradas al inicio del archivo (antes de dibujarRegion)
local grafModo  = "2d"  -- "2d" o "3d"
local resultadoNumTexto = ""

local resultadoIntLineas = {}

local scrollY = 0
local lineHeight = 14
local totalLineas = 0

local function wrapText(gc, text, maxw)
    local out = {}
    for linea in (text.."\n"):gmatch("([^\n]*)\n") do
        if linea == "" then table.insert(out, "")
        else
            local cur = ""
            for palabra in linea:gmatch("%S+") do
                local prueba = (cur=="") and palabra or (cur.." "..palabra)
                if gc:getStringWidth(prueba) > maxw and cur ~= "" then
                    table.insert(out, cur) cur = palabra
                else cur = prueba end
            end
            table.insert(out, cur)
        end
    end
    return out
end

local function irAMenu()
    pantalla = "menu"
    platform.window:invalidate()
end

local function iniciarFormNum(idx)
    seleccion = idx
    campoNumActual = 1
    valoresNum = {}
    for i,c in ipairs(problemasNum[idx].campos) do valoresNum[i]=c.default end
    pantalla = "form_num"
end

local function calcularNum()
    local p = problemasNum[seleccion]
    local ok, res = pcall(p.resolver, valoresNum)
    resultadoNumTexto = ok and res or ("Error interno: "..tostring(res))
    pantalla = "resultado_num"
    scrollY = 0
end

local function iniciarFormInt(presetEj)
    seleccion = (presetEj==3) and 3 or 5
    if presetEj == 3 then
        cargarCampos("5*x^3*cos(y^3)","0","2*sqrt(2)","x^2/4","2")
        ordenInt = "dy_dx"
    elseif presetEj == 5 then
        -- orden dx dy: campo a,b = limites de y; yi,ys = limites de x
        cargarCampos("x^2*y*exp(y^2)","0","sqrt(2)","y^2","4-y^2")
        ordenInt = "dx_dy"
    else
        cargarCampos("","","","","")
        ordenInt = "dy_dx"
    end
    campoActual = 1
    presetIdx = 1
    pantalla = "form_int"
end

-- ============================================================
-- DIBUJO
-- ============================================================
function on.construction()
    on.resize()
end

function on.paint(gc)
    local w, h = platform.window:width(), platform.window:height()
    gc:setColorRGB(255,255,255)
    gc:fillRect(0,0,w,h)
    gc:setColorRGB(0,0,0)

    if pantalla == "menu" then
        gc:setFont("sansserif","b",11)
        gc:drawString("CALCULUS TOOLKIT - EXAMEN", 10, 4, "top")
        gc:setFont("sansserif","r",8)
        gc:drawString("Flechas + Enter", 10, 18, "top")
        gc:setFont("sansserif","r",10)
        local y = 34
        local itemH = 20
        for i, texto in ipairs(menu) do
            if i == seleccion then
                gc:setColorRGB(0,80,190) gc:fillRect(8, y, w-16, itemH-2) gc:setColorRGB(255,255,255)
            else
                gc:setColorRGB(225,230,240) gc:fillRect(8, y, w-16, itemH-2) gc:setColorRGB(0,0,0)
            end
            gc:drawString(texto, 14, y+3, "top")
            y = y + itemH
        end

    elseif pantalla == "form_num" then
        local p = problemasNum[seleccion]
        gc:setFont("sansserif","b",10)
        gc:drawString(menu[seleccion] .. " - Ingrese datos", 8, 4, "top")
        gc:setFont("sansserif","r",7)
        gc:drawString("Numeros+punto  Enter=siguiente/calcular  Esc=menu", 8, 17, "top")
        gc:drawLine(8, 28, w-8, 28)
        gc:setFont("sansserif","r",9)
        local y = 34
        for i, campo in ipairs(p.campos) do
            if i == campoNumActual then
                gc:setColorRGB(0,80,190) gc:fillRect(8, y, w-16, 32) gc:setColorRGB(255,255,255)
            else
                gc:setColorRGB(240,240,240) gc:fillRect(8, y, w-16, 32) gc:setColorRGB(0,0,0)
            end
            gc:drawString(campo.nombre, 12, y+2, "top")
            gc:setFont("sansserif","b",11)
            local valTxt = valoresNum[i]
            if i==campoNumActual then valTxt = valTxt.."_" end
            gc:drawString(valTxt, 12, y+15, "top")
            gc:setFont("sansserif","r",9)
            y = y + 36
        end
        gc:setFont("sansserif","r",8) gc:setColorRGB(80,80,80)
        gc:drawString("(En el ultimo campo, Enter calcula)", 8, y+4, "top")

    elseif pantalla == "resultado_num" then
        gc:setFont("sansserif","b",10)
        gc:drawString(menu[seleccion], 8, 4, "top")
        gc:setFont("sansserif","r",7)
        gc:drawString("Flechas=scroll  Esc=editar  Backspace=menu", 8, 17, "top")
        gc:drawLine(8, 28, w-8, 28)
        gc:setFont("sansserif","r",9)
        local lineas = wrapText(gc, resultadoNumTexto, w-20)
        totalLineas = #lineas
        local y = 32 - scrollY
        for _, linea in ipairs(lineas) do
            if y > 28 and y < h then gc:drawString(linea, 12, y, "top") end
            y = y + lineHeight
        end

    elseif pantalla == "form_int" then
        gc:setColorRGB(0,80,190) gc:fillRect(0,0,w,18) gc:setColorRGB(255,255,255)
        gc:setFont("sansserif","b",10)
        gc:drawString("Integral doble ("..
            (ordenInt=="dy_dx" and "dy dx)" or "dx dy)"), 6, 2, "top")
        gc:setColorRGB(0,0,0)
        gc:setFont("sansserif","r",9)
        -- Etiquetas dependen del orden de integracion
        local etiq = {}
        if ordenInt == "dy_dx" then
            etiq = {"f(x,y) =", "x: a =", "x: b =", "y inf(x) =", "y sup(x) ="}
        else
            etiq = {"f(x,y) =", "y: a =", "y: b =", "x inf(y) =", "x sup(y) ="}
        end
        local y = 22
        for i, c in ipairs(campos) do
            gc:setColorRGB(0,0,0)
            gc:drawString(etiq[i], 6, y, "top")
            if i == campoActual then
                gc:setColorRGB(0,80,190) gc:drawRect(6, y+13, w-12, 20)
            else
                gc:setColorRGB(225,225,235) gc:fillRect(6, y+13, w-12, 20)
            end
            gc:setColorRGB(0,0,0)
            local txt = c.valor
            if i==campoActual then txt = txt.."_" end
            gc:drawString(txt, 10, y+16, "top")
            y = y + 40
        end
        gc:setFont("sansserif","r",7) gc:setColorRGB(60,60,60)
        gc:drawString("Enter: sig  Esc: menu  O: cambiar orden (dy_dx/dx_dy)", 6, y+2, "top")
        gc:drawString("Tab: ejemplos  actual: "..presets[presetIdx].nom, 6, y+13, "top")
        gc:drawString("Sintaxis: sin() cos() sqrt() exp() pi  ^ *", 6, y+24, "top")

    elseif pantalla == "resultado_int" then
        gc:setColorRGB(0,80,190) gc:fillRect(0,0,w,18) gc:setColorRGB(255,255,255)
        gc:setFont("sansserif","b",10)
        local tituloG = not modoGrafica and "Resultado" or
                        (grafModo=="3d" and "Grafica 3D superficie" or "Grafica 2D region")
        gc:drawString(tituloG, 6, 2, "top")
        gc:setColorRGB(0,0,0)
        gc:setFont("sansserif","r",7)
        if modoGrafica then
            gc:drawString("G=2D  D=3D  +/-=zoom  flechas=pan  R=reset", 6, h-12, "top")
        else
            gc:drawString("G=graf2D  D=graf3D  Flechas=scroll  Esc=editar", 6, h-12, "top")
        end
        if modoGrafica then
            if grafModo == "3d" then
                dibujar3D(gc, w, h-16)
            else
                dibujarRegion(gc, w, h-16)
            end
        else
            gc:setFont("sansserif","r",9)
            local texto = table.concat(resultadoIntLineas, "\n")
            local lineas = wrapText(gc, texto, w-12)
            totalLineas = #lineas
            local y = 22 - scrollY
            for _, linea in ipairs(lineas) do
                if y > 18 and y < h-14 then gc:drawString(linea, 6, y, "top") end
                y = y + lineHeight
            end
        end

    elseif pantalla == "form_pol" then
        gc:setColorRGB(0,80,190) gc:fillRect(0,0,w,18) gc:setColorRGB(255,255,255)
        gc:setFont("sansserif","b",10)
        gc:drawString("Coord. Polares / Cilindricas", 6, 2, "top")
        gc:setColorRGB(0,0,0)
        gc:setFont("sansserif","r",9)
        local y = 22
        for i, c in ipairs(camposPol) do
            gc:setColorRGB(0,0,0)
            gc:drawString(c.nombre, 6, y, "top")
            if i == campoPolarActual then
                gc:setColorRGB(0,80,190) gc:drawRect(6, y+13, w-12, 20)
            else
                gc:setColorRGB(225,225,235) gc:fillRect(6, y+13, w-12, 20)
            end
            gc:setColorRGB(0,0,0)
            local txt = c.valor
            if i==campoPolarActual then txt = txt.."_" end
            gc:drawString(txt, 10, y+16, "top")
            y = y + 40
        end
        gc:setFont("sansserif","r",7) gc:setColorRGB(60,60,60)
        gc:drawString("V=∫∫(z_sup-z_inf)*r dr dt   (jacobiano r incluido)", 6, y+2, "top")
        gc:drawString("Tab: ejemplos  actual: "..presetsPol[presetPolIdx].nom, 6, y+13, "top")
        gc:drawString("Usar: r, theta, sin() cos() sqrt() exp() pi", 6, y+24, "top")

    elseif pantalla == "resultado_pol" then
        gc:setColorRGB(0,80,190) gc:fillRect(0,0,w,18) gc:setColorRGB(255,255,255)
        gc:setFont("sansserif","b",10)
        gc:drawString(modoGraficaPol and "Grafica region (XY)" or "Resultado polares", 6, 2, "top")
        gc:setColorRGB(0,0,0)
        gc:setFont("sansserif","r",7)
        gc:drawString("G=grafica/texto  Flechas=scroll  Esc=editar", 6, h-12, "top")
        if modoGraficaPol then
            dibujarRegionPolar(gc, w, h-16)
        else
            gc:setFont("sansserif","r",9)
            local texto = table.concat(resultadoPolLineas, "\n")
            local lineas = wrapText(gc, texto, w-12)
            totalLineas = #lineas
            local y = 22 - scrollY
            for _, linea in ipairs(lineas) do
                if y > 18 and y < h-14 then gc:drawString(linea, 6, y, "top") end
                y = y + lineHeight
            end
        end
    end
end

function on.resize()
    platform.window:invalidate()
end

-- ============================================================
-- TECLADO
-- ============================================================
function on.charIn(ch)
    if pantalla == "form_num" then
        valoresNum[campoNumActual] = valoresNum[campoNumActual] .. ch
    elseif pantalla == "form_int" then
        if ch=="k" or ch=="K" then
            ordenInt = (ordenInt=="dy_dx") and "dx_dy" or "dy_dx"
        else
            campos[campoActual].valor = campos[campoActual].valor .. ch
        end
    elseif pantalla == "form_pol" then
        camposPol[campoPolarActual].valor = camposPol[campoPolarActual].valor .. ch
    elseif pantalla == "resultado_int" then
        if ch=="g" or ch=="G" then
            if grafModo == "2d" then
                modoGrafica = not modoGrafica
                if modoGrafica then grafZoom=1.0 grafPanX=0 grafPanY=0 grafModo="2d" end
            else
                grafModo = "2d"
            end
        elseif ch=="d" or ch=="D" then
            modoGrafica = true
            grafModo = "3d"
            grafZoom=1.0 grafPanX=0 grafPanY=0
            grafRotX=0.4 grafRotZ=0.6
        elseif ch=="+" and modoGrafica then
            grafZoom = math.min(grafZoom * 1.5, 20)
        elseif ch=="-" and modoGrafica then
            grafZoom = math.max(grafZoom / 1.5, 0.1)
        elseif (ch=="r" or ch=="R") and modoGrafica then
            grafZoom=1.0 grafPanX=0 grafPanY=0
        end
    elseif pantalla == "resultado_pol" then
        if ch=="g" or ch=="G" then
            modoGraficaPol = not modoGraficaPol
            if modoGraficaPol then grafZoom=1.0 grafPanX=0 grafPanY=0 end
        elseif ch=="+" and modoGraficaPol then
            grafZoom = math.min(grafZoom * 1.5, 20)
        elseif ch=="-" and modoGraficaPol then
            grafZoom = math.max(grafZoom / 1.5, 0.1)
        elseif (ch=="r" or ch=="R") and modoGraficaPol then
            grafZoom=1.0 grafPanX=0 grafPanY=0
            grafRotX=0.4 grafRotZ=0.6
        end
    end
    platform.window:invalidate()
end

function on.backspaceKey()
    if pantalla == "form_num" then
        local v = valoresNum[campoNumActual]
        if #v>0 then valoresNum[campoNumActual]=v:sub(1,#v-1) end
    elseif pantalla == "resultado_num" then
        irAMenu()
    elseif pantalla == "form_int" then
        local v = campos[campoActual].valor
        if #v>0 then campos[campoActual].valor=v:sub(1,#v-1) end
    elseif pantalla == "form_pol" then
        local v = camposPol[campoPolarActual].valor
        if #v>0 then camposPol[campoPolarActual].valor=v:sub(1,#v-1) end
    end
    platform.window:invalidate()
end

function on.clearKey()
    if pantalla == "form_int" then campos[campoActual].valor=""
    elseif pantalla == "form_num" then valoresNum[campoNumActual]=""
    elseif pantalla == "form_pol" then camposPol[campoPolarActual].valor=""
    end
    platform.window:invalidate()
end

function on.tabKey()
    if pantalla == "form_int" then
        presetIdx = presetIdx + 1
        if presetIdx > #presets then presetIdx = 1 end
        local p = presets[presetIdx]
        cargarCampos(p.f, p.a, p.b, p.yi, p.ys)
        -- Actualizar orden de integracion segun el preset
        ordenInt = p.orden or "dy_dx"
        campoActual = 1
    elseif pantalla == "form_pol" then
        presetPolIdx = presetPolIdx + 1
        if presetPolIdx > #presetsPol then presetPolIdx = 1 end
        local p = presetsPol[presetPolIdx]
        cargarCamposPol(p.f, p.ri, p.rs, p.ti, p.ts)
        campoPolarActual = 1
    elseif pantalla == "resultado_num" then
        calcularNum()
    elseif pantalla == "resultado_int" then
        resultadoIntLineas = evaluarIntegral()
        scrollY = 0
    elseif pantalla == "resultado_pol" then
        resultadoPolLineas = evaluarPolar()
        scrollY = 0
    end
    platform.window:invalidate()
end

function on.enterKey()
    if pantalla == "menu" then
        if seleccion==1 or seleccion==2 or seleccion==4 then
            iniciarFormNum(seleccion)
        elseif seleccion==3 then
            iniciarFormInt(3)
        elseif seleccion==5 then
            iniciarFormInt(5)
        elseif seleccion==6 then
            -- Cargar P1 como ejemplo por defecto (igual que los otros problemas)
            cargarCamposPol("9-r^2","0","sqrt(3)","0","2*pi")
            campoPolarActual = 1
            presetPolIdx = 2  -- apunta al preset P1
            pantalla = "form_pol"
        elseif seleccion==7 then
            cargarCampos("sin(x)*cos(y)","0","pi/2","0","pi/2")
            campoActual = 1
            presetIdx = 6
            ordenInt = "dy_dx"
            pantalla = "form_int"
        end
    elseif pantalla == "form_num" then
        local p = problemasNum[seleccion]
        if campoNumActual < #p.campos then campoNumActual = campoNumActual + 1
        else calcularNum() end
    elseif pantalla == "form_int" then
        if campoActual < #campos then
            campoActual = campoActual + 1
        else
            resultadoIntLineas = evaluarIntegral()
            pantalla = "resultado_int"
            scrollY = 0
            modoGrafica = false
        end
    elseif pantalla == "form_pol" then
        if campoPolarActual < #camposPol then
            campoPolarActual = campoPolarActual + 1
        else
            resultadoPolLineas = evaluarPolar()
            pantalla = "resultado_pol"
            scrollY = 0
            modoGraficaPol = false
        end
    end
    platform.window:invalidate()
end

function on.arrowUp()
    if pantalla == "menu" then
        seleccion = seleccion - 1
        if seleccion < 1 then seleccion = #menu end
    elseif pantalla == "form_num" then
        campoNumActual = campoNumActual - 1
        if campoNumActual < 1 then campoNumActual = #problemasNum[seleccion].campos end
    elseif pantalla == "resultado_num" then
        scrollY = math.max(0, scrollY - lineHeight*2)
    elseif pantalla == "form_int" then
        campoActual = campoActual - 1
        if campoActual < 1 then campoActual = #campos end
    elseif pantalla == "resultado_int" then
        if modoGrafica and grafModo == "3d" then
            grafRotX = grafRotX - 0.15  -- elevar camara 3D
        elseif modoGrafica then
            grafPanY = grafPanY - (1/grafZoom) * 0.3  -- pan 2D
        else
            scrollY = math.max(0, scrollY - lineHeight*2)
        end
    elseif pantalla == "form_pol" then
        campoPolarActual = campoPolarActual - 1
        if campoPolarActual < 1 then campoPolarActual = #camposPol end
    elseif pantalla == "resultado_pol" then
        if modoGraficaPol then
            grafPanY = grafPanY - (1/grafZoom) * 0.3
        else
            scrollY = math.max(0, scrollY - lineHeight*2)
        end
    end
    platform.window:invalidate()
end

function on.arrowDown()
    if pantalla == "menu" then
        seleccion = seleccion + 1
        if seleccion > #menu then seleccion = 1 end
    elseif pantalla == "form_num" then
        campoNumActual = campoNumActual + 1
        if campoNumActual > #problemasNum[seleccion].campos then campoNumActual = 1 end
    elseif pantalla == "resultado_num" then
        local maxS = math.max(0, totalLineas*lineHeight - 100)
        scrollY = math.min(maxS, scrollY + lineHeight*2)
    elseif pantalla == "form_int" then
        campoActual = campoActual + 1
        if campoActual > #campos then campoActual = 1 end
    elseif pantalla == "resultado_int" then
        if modoGrafica and grafModo == "3d" then
            grafRotX = grafRotX + 0.15  -- bajar camara 3D
        elseif modoGrafica then
            grafPanY = grafPanY + (1/grafZoom) * 0.3  -- pan 2D
        else
            local maxS = math.max(0, totalLineas*lineHeight - 100)
            scrollY = math.min(maxS, scrollY + lineHeight*2)
        end
    elseif pantalla == "form_pol" then
        campoPolarActual = campoPolarActual + 1
        if campoPolarActual > #camposPol then campoPolarActual = 1 end
    elseif pantalla == "resultado_pol" then
        if modoGraficaPol then
            grafPanY = grafPanY + (1/grafZoom) * 0.3
        else
            local maxS = math.max(0, totalLineas*lineHeight - 100)
            scrollY = math.min(maxS, scrollY + lineHeight*2)
        end
    end
    platform.window:invalidate()
end

function on.arrowLeft()
    if pantalla=="resultado_int" and modoGrafica and grafModo=="3d" then
        grafRotZ = grafRotZ - 0.15
        platform.window:invalidate()
    elseif (pantalla=="resultado_int" and modoGrafica) or
           (pantalla=="resultado_pol" and modoGraficaPol) then
        grafPanX = grafPanX - (1/grafZoom) * 0.3
        platform.window:invalidate()
    end
end

function on.arrowRight()
    if pantalla=="resultado_int" and modoGrafica and grafModo=="3d" then
        grafRotZ = grafRotZ + 0.15
        platform.window:invalidate()
    elseif (pantalla=="resultado_int" and modoGrafica) or
           (pantalla=="resultado_pol" and modoGraficaPol) then
        grafPanX = grafPanX + (1/grafZoom) * 0.3
        platform.window:invalidate()
    end
end
function on.escapeKey()
    if pantalla == "form_num" then irAMenu()
    elseif pantalla == "resultado_num" then pantalla="form_num" platform.window:invalidate()
    elseif pantalla == "form_int" then irAMenu()
    elseif pantalla == "resultado_int" then pantalla="form_int" platform.window:invalidate()
    elseif pantalla == "form_pol" then irAMenu()
    elseif pantalla == "resultado_pol" then pantalla="form_pol" platform.window:invalidate()
    end
end

-- Alias para firmwares que usan on.escape en vez de on.escapeKey
function on.escape()
    on.escapeKey()
end
