breed [ riders rider ]
breed [ pedidos pedido ]

globals [
  total-generados total-entregados total-robados total-detectados
  total-caducados total-bonos total-multas
  decisiones-recientes
]

riders-own [
  perfil
  preferencia-entregar sensibilidad-bono sensibilidad-multa valor-comida-propio
  tasa-aprendizaje aprendizaje
  energia
  proxima-asignacion
]

pedidos-own [
  repartidor recogido?
  tarifa valor-comida bono-acordado
  cliente-x cliente-y
  creado-en
]

to setup
  if seed != round seed or seed < -2147483648 or seed > 2147483647 [
    user-message "Seed debe ser un entero entre -2147483648 y 2147483647."
    stop
  ]
  clear-all
  random-seed seed
  set decisiones-recientes []
  ask patches [ set pcolor rgb 28 36 47 ]
  create-riders numero-riders [
    setxy random-xcor random-ycor
    set shape "person"
    set size 1.35
    set energia 100
    set perfil who mod 3
    if perfil = 0 [
      set preferencia-entregar 5
      set sensibilidad-bono 0.7
      set sensibilidad-multa 1.1
      set valor-comida-propio 0.30
    ]
    if perfil = 1 [
      set preferencia-entregar 0
      set sensibilidad-bono 1.4
      set sensibilidad-multa 0.8
      set valor-comida-propio 0.45
    ]
    if perfil = 2 [
      set preferencia-entregar -2
      set sensibilidad-bono 0.65
      set sensibilidad-multa 0.45
      set valor-comida-propio 0.55
    ]
    set preferencia-entregar preferencia-entregar + random-normal 0 1.2
    set tasa-aprendizaje 0.4 + random-float 0.8
  ]
  generar-pedidos 15 0
  ask riders [ actualizar-color ]
  reset-ticks
end

to go
  if ticks > 0 and ticks mod 15 = 0 [
    generar-pedidos pedidos-por-lote ticks
  ]
  let caducados pedidos with [ repartidor = nobody and ticks - creado-en >= 120 ]
  set total-caducados total-caducados + count caducados
  ask caducados [ die ]

  ask riders [ avanzar-rider ]
  ask riders [ actualizar-color ]
  tick
end

to generar-pedidos [ cantidad instante ]
  set total-generados total-generados + cantidad
  create-pedidos cantidad [
    set shape "square"
    set color yellow
    set size 0.65
    setxy random-xcor random-ycor
    set cliente-x random-xcor
    set cliente-y random-ycor
    set tarifa 3 + random 5
    set valor-comida 10 + random 25
    set creado-en instante
    set repartidor nobody
    set recogido? false
  ]
end

to avanzar-rider
  let encargo one-of pedidos with [ repartidor = myself ]
  if encargo = nobody [
    set energia min (list 100 (energia + 1.2))
    if ticks < proxima-asignacion [ stop ]
    set encargo min-one-of (pedidos with [ repartidor = nobody ]) [ distance myself ]
    if encargo = nobody [ stop ]
    ask encargo [ set repartidor myself ]
  ]

  ifelse [ recogido? ] of encargo [
    let destino-x [ cliente-x ] of encargo
    let destino-y [ cliente-y ] of encargo
    mover-hacia destino-x destino-y 0.8
    if distancexy destino-x destino-y < 0.000001 [ completar-entrega encargo ]
  ] [
    let origen-x [ xcor ] of encargo
    let origen-y [ ycor ] of encargo
    mover-hacia origen-x origen-y 0.5
    if distancexy origen-x origen-y < 0.000001 [ decidir-en-recogida encargo ]
  ]
end

to mover-hacia [ destino-x destino-y esfuerzo ]
  let restante distancexy destino-x destino-y
  if restante = 0 [ stop ]
  let paso min (list 1.4 restante)
  ifelse restante <= paso [
    setxy destino-x destino-y
  ] [
    facexy destino-x destino-y
    fd paso
  ]
  set energia max (list 0 (energia - esfuerzo * paso))
end

to decidir-en-recogida [ encargo ]
  let distancia-entrega distancexy ([ cliente-x ] of encargo) ([ cliente-y ] of encargo)
  let probabilidad probabilidad-entregar ([ tarifa ] of encargo) ([ valor-comida ] of encargo) distancia-entrega
  ifelse random-float 1 < probabilidad [
    registrar-decision 0
    ask encargo [
      set recogido? true
      set bono-acordado bono-entrega
      hide-turtle
    ]
  ] [
    registrar-decision 1
    ejecutar-robo encargo
  ]
end

to-report probabilidad-entregar [ pago valor distancia-entrega ]
  let coste-viaje (0.10 * distancia-entrega) * (1 + (100 - energia) / 70)
  let utilidad-entregar pago + sensibilidad-bono * bono-entrega - coste-viaje
  let coste-suspension 0.15 * ticks-suspension
  let coste-esperado (deteccion / 100) * (sensibilidad-multa * multa-robo + coste-suspension)
  let utilidad-robar valor-comida-propio * valor - coste-esperado
  let diferencia utilidad-entregar - utilidad-robar + preferencia-entregar + aprendizaje
  report 1 / (1 + exp (0 - diferencia / 2.5))
end

to ejecutar-robo [ encargo ]
  set total-robados total-robados + 1
  ifelse random-float 100 < deteccion [
    set total-detectados total-detectados + 1
    set total-multas total-multas + multa-robo
    set proxima-asignacion ticks + ticks-suspension + 1
    aprender (tasa-aprendizaje * (0.8 + multa-robo / 20 + ticks-suspension / 50))
  ] [
    aprender (-0.65 * tasa-aprendizaje)
  ]
  ask encargo [ die ]
end

to completar-entrega [ encargo ]
  let bono [ bono-acordado ] of encargo
  set total-entregados total-entregados + 1
  set total-bonos total-bonos + bono
  aprender (tasa-aprendizaje * (0.15 + bono / 12))
  ask encargo [ die ]
end

to aprender [ cambio ]
  set aprendizaje max (list -6 (min (list 6 (0.97 * aprendizaje + cambio))))
end

to registrar-decision [ robo ]
  set decisiones-recientes lput robo decisiones-recientes
  if length decisiones-recientes > 50 [
    set decisiones-recientes but-first decisiones-recientes
  ]
end

to-report tendencia-entregar
  ;; Se evalúa el mismo pedido de referencia para todos los riders.
  report 100 * probabilidad-entregar 5 22 16
end

to actualizar-color
  let tendencia tendencia-entregar / 100
  set color rgb (round (230 - 158 * tendencia)) (round (78 + 126 * tendencia)) (round (85 + 62 * tendencia))
end

to-report media-perfil [ grupo ]
  let miembros riders with [ perfil = grupo ]
  if not any? miembros [ report 0 ]
  report mean [ tendencia-entregar ] of miembros
end

to-report porcentaje-robos-recientes
  if empty? decisiones-recientes [ report 0 ]
  report 100 * mean decisiones-recientes
end
@#$#@#$#@
GRAPHICS-WINDOW
255
10
653
409
-1
-1
9.5
1
14
1
1
1
0
0
0
1
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
10
10
124
45
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
130
10
244
45
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

INPUTBOX
10
51
244
109
seed
42.0
1
0
Number

SLIDER
10
118
244
152
Riders al iniciar
numero-riders
3
90
30.0
3
1
NIL
HORIZONTAL

SLIDER
10
157
244
191
Pedidos cada 15 ticks
pedidos-por-lote
0
30
12.0
1
1
NIL
HORIZONTAL

SLIDER
10
212
244
246
Bono por entrega
bono-entrega
0
15
1.0
0.5
1
€
HORIZONTAL

SLIDER
10
251
244
285
Detección de robos
deteccion
0
100
40.0
1
1
%
HORIZONTAL

SLIDER
10
290
244
324
Multa por robo detectado
multa-robo
0
30
6.0
1
1
€
HORIZONTAL

SLIDER
10
329
244
363
Suspensión
ticks-suspension
0
80
10.0
1
1
ticks
HORIZONTAL

TEXTBOX
12
195
240
212
Política de la plataforma
11
0.0
0

TEXTBOX
259
417
654
459
Riders: rojo = menor tendencia a entregar, turquesa = mayor.\nCuadrados amarillos: puntos de recogida de los pedidos.
11
0.0
0

MONITOR
10
378
124
424
Entregados
total-entregados
0
1
11

MONITOR
130
378
244
424
Robados
total-robados
0
1
11

MONITOR
10
429
124
475
Detectados
total-detectados
0
1
11

MONITOR
130
429
244
475
Caducados
total-caducados
0
1
11

MONITOR
10
480
124
526
Bonos pagados (€)
total-bonos
2
1
11

MONITOR
130
480
244
526
Multas (€)
total-multas
2
1
11

PLOT
670
10
1038
220
Tendencia a entregar por perfil (%)
Ticks
%
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Alta preferencia inicial" 1.0 0 -10899396 true "" "plot media-perfil 0"
"Sensible al bono" 1.0 0 -13345367 true "" "plot media-perfil 1"
"Mayor valoración de la comida" 1.0 0 -2674135 true "" "plot media-perfil 2"

PLOT
670
231
1038
441
Robos en las últimas 50 decisiones (%)
Ticks
%
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"Robos" 1.0 0 -2674135 true "" "if not empty? decisiones-recientes [ plotxy ticks porcentaje-robos-recientes ]"
@#$#@#$#@
## Qué puedes observar

Cada rider decide al recoger un pedido si lo entrega o se queda con la comida. El color del rider cambia continuamente del rojo al turquesa según su probabilidad de entregar un pedido de referencia de 5 €, comida de 22 € y 16 unidades de distancia. El gráfico superior muestra esa misma medida promediada por perfil. El inferior recoge las decisiones que realmente se tomaron, sobre las últimas 50 recogidas o las disponibles si hay menos.

## Cómo usarlo

1. Introduce un entero en **seed**, justo debajo de **Setup** y **Go**.
2. Pulsa **Setup** y luego **Go**. Los mismos valores iniciales, la misma semilla y los mismos cambios de política en los mismos ticks reproducen la trayectoria en NetLogo 6.4.
3. Cambia el bono, la detección, la multa o la suspensión durante la ejecución. Los cambios se aplican a las nuevas decisiones de recogida. El bono queda fijado al decidir entregar y se paga al completar el viaje.
4. Para comparar políticas desde el principio, vuelve a pulsar **Setup** con la misma semilla y compara los resultados al mismo tick. El número de riders se aplica al iniciar.

## Reglas del modelo

Los tres perfiles difieren en su preferencia inicial por entregar, su respuesta al bono y a la multa, y el valor que dan a quedarse con la comida. Cada rider tiene además una variación individual en su preferencia y en cuánto aprende de cada experiencia.

La decisión es probabilística. Entregar resulta más atractivo con mejor tarifa o bono y menos atractivo cuanto más lejos está el cliente o mayor es la fatiga. Robar resulta más atractivo cuanto mayor es el valor percibido de la comida. El coste esperado del robo combina la probabilidad de detección con la multa y el tiempo de suspensión.

Una entrega refuerza la tendencia a entregar, especialmente si cobra un bono. Un robo detectado también la refuerza y retrasa la próxima asignación. Un robo sin detectar reduce esa tendencia. Cada rider recupera energía cuando está sin encargo. La asignación y la recogida se registran en el pedido. Un pedido sin asignar caduca a los 120 ticks.

Los importes, perfiles y parámetros de aprendizaje son supuestos de simulación. Los monitores de bonos y multas muestran acumulados de la plataforma.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 195 90 220 178 183 178 179 285 151 285 146 204 135 285 106 285 111 178 78 178

square
false
0
Rectangle -7500403 true true 30 30 270 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
setup
repeat 120 [ go ]
@#$#@#$#@

@#$#@#$#@

@#$#@#$#@

@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
