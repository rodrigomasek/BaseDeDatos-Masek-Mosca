use juegos_t;
#1 Listar todos los jugadores de Argentina, ordenados alfabéticamente por apellido. 

select j.nombre from jugadores j
where pais = "argentina"
order by apellido asc;

#2  Mostrar los videojuegos con edad mínima mayor o igual a 16 años.

 select j.nombre from juegos j
 where clasi_e = "mature";

#3 Listar el nombre de cada equipo junto con el nombre y apellido de su capitán.
 
 select e.nombre, e.capitan from equipos e;
 
 #4 . Obtener todas las inscripciones mostrando: nombre del eq
 select j.juga_id, min(j.fecha_n)
 from jugadores j
 group by j.pais;uipo, nombre del torneo,
 # fecha de inscripción y posición final.

 select e.nombre, t.nombre, the.fecha_ins, the.posicion from torneo_equipos the
 join equipos e on the.equi_id = e.equi_id
 join torneo t on the.torneo_id = t.torneo_id;
 
 #5  Calcular cuántos jugadores hay por país.
 
 select j.pais, count(j.juga_id) from jugadores j
 group by j.pais;
 
 #6 Calcular el premio total ofrecido por todos los torneos de cada videojuego.
 
 select j.nombre ,sum(t.premio) from torneo t
 join juegos j on j.juegos_id = t.juegos_id
 group by j.nombre;
 
 #7 Obtener el promedio de edad mínima de los videojuegos por género.
 select j.nombre, avg(j.clasi_e) from juegos j
 group by j.genero;
 
 #8 Listar los equipos que participaron en más de 5 torneos.
 
 select the.equi_id from torneo_equipos the
 group by the.equi_id
 having count(the.equi_id) > 5;
 
 #9 Hacer un top 5 de los torneos con mayor premio ofrecido.
 
 select t.nombre from torneo t
 order by t.premio
 limit 5;
 
 #10 Listar los jugadores que están en equipos que ganaron al menos un torneo.
 
 select j.nombre from jugadores j
 join equipos e on e.equi_id = j.equi_id
 join torneo_equipos the on the.equi_id = e.equi_id 
 where the.posicion = 1;
 
 #11 Mostrar el videojuego con más torneos organizados.

 select t.juegos_id, count(juegos_id) as cantidad from torneo t
 group by t.juegos_id
 order by cantidad desc
 limit 1;
 
 #12 . Listar los jugadores más jóvenes de cada país
 
 select j.juga_id, min(j.fecha_n)
 from jugadores j
 group by j.pais;
 
 #13 Duplicar el premio de los torneos que tienen menos de 3 equipos inscritos
 
 update torneo t
 set t.premio = t.premio * 2
 where t.torneo_id in
 (select te.torneo_id
 from torneo_equipos te
 group by te.torneo_id
 having count(te.equi_id) >= 3);
 
 
 
#14  Actualizar el nombre de todos los videojuegos agregándoles el prefijo "[Popular]" si
-- tienen más de 2 torneos asociados.
 
 update juegos j
 set j.nombre = concat("popular", j.nombre)
 where j.juegos_id in
 (select t.juegos_id
 from torneo t
 group by juegos_id 
 having  count(torneo_id) > 2);
 
 #15 Actualizar la edad mínima de todos los videojuegos al promedio de edades mínimas de
-- su mismo género.
 
 update juegos j
 set clasi_e = (select avg(j2.clasi_e) 
 				from juegos j2
				where j2.genero = j.genero);
 
 #16  Eliminar a los jugadores que no pertenecen a ningún equipo.
 
 delete from jugadores j
 where j.equi_id not in
 (select e.equi_id
 from equipos e);
 
 #17 Eliminar los equipos que no salieron en el top 3 de ningún torneo.
 
 delete from equipos e
 where e.equi_id not in
 (select te.equi_id
 from torneo_equipos te
 where posicion <= 3);
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 