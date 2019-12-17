-- База курсовой работы на примере Кинопоиск 


DROP DATABASE IF EXISTS kinopoisk_test;
CREATE DATABASE kinopoisk_test; 
USE kinopoisk_test; 

-- список режисеров 
DROP TABLE IF EXISTS directors;
CREATE TABLE directors ( 
	id SERIAL PRIMARY KEY,
	name VARCHAR(40),
	bio TEXT,
	birthday DATE,
	gender CHAR(1),
	
	INDEX (name)
	
);

-- таблица пользователей c основной информацией 
DROP TABLE IF EXISTS users; 
CREATE TABLE users  ( 
	id SERIAL PRIMARY KEY,
	nickname VARCHAR(10)UNIQUE,
	email VARCHAR(30) UNIQUE,
	`password_hash` VARCHAR(128),
	favorite_director BIGINT UNSIGNED NOT NULL,
	telephone_number VARCHAR(12) UNIQUE NOT NULL ,
	regestration_date  DATETIME DEFAULT NOW(),
	
	FOREIGN KEY (favorite_director) REFERENCES directors(id) on update cascade 
	
);
-- типы жанров для фильмов. 
DROP TABLE IF EXISTS genres_type;
CREATE TABLE genres_type (
	id SERIAL PRIMARY KEY,
	`type` VARCHAR(30) UNIQUE NOT NULL
	
);


-- Основная таблица с фильмами, где есть один основной жанр, и один дополнительный. Оба ссылаются на  таблицу типо
DROP TABLE IF EXISTS films;
CREATE TABLE films ( 
	id SERIAL PRIMARY KEY,
	film_name VARCHAR(30) NOT NULL, 
	release_date DATE NOT NULL, 
	director_id BIGINT UNSIGNED NOT NULL,
	main_style BIGINT UNSIGNED NOT NULL,
	sub_style BIGINT UNSIGNED NOT NULL,
	budget_EURO INT,
	film_total_score INT,
	
	FOREIGN KEY (main_style) REFERENCES genres_type(id) on update cascade,
	FOREIGN KEY (sub_style) REFERENCES genres_type(id) on update cascade,
	
	INDEX (director_id),
	INDEX (film_name)
);


-- промежуточная таблица для директоров что бы сделать связь М : М  
DROP TABLE IF EXISTS directors_films;
CREATE TABLE directors_films ( 
		id_director BIGINT UNSIGNED NOT NULL,
		id_film BIGINT UNSIGNED NOT NULL,
		
		PRIMARY KEY (id_director,id_film ),
		FOREIGN KEY (id_director) REFERENCES directors(id) on update cascade on delete cascade,
		FOREIGN KEY (id_film) REFERENCES films(id) on update cascade on delete cascade
);

-- список фильмов добавленных пользователями в избранное
DROP TABLE IF EXISTS favorites;
CREATE TABLE favorites ( 
		user_id BIGINT UNSIGNED  NOT NULL,
		film_id BIGINT UNSIGNED NOT NULL,
		to_favorite_time DATETIME NOT NULL ,  
		
		PRIMARY KEY (user_id, film_id),
		FOREIGN KEY (user_id) REFERENCES users(id)on update cascade on delete cascade,
		FOREIGN KEY (film_id) REFERENCES films(id)on update cascade on delete cascade
		
);
-- Обзоры на фильмы сделанные пользователями.

DROP TABLE IF EXISTS revisions; 
CREATE TABLE revisions  ( 	   
	   user_revision BIGINT UNSIGNED NOT NULL,
	   film_revision BIGINT UNSIGNED NOT NULL,
	   created_at DATETIME DEFAULT NOW(),
	   body TEXT,
	   `status` ENUM ('approved', 'rejected', 'on moderation'),
	   updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP, 
	   
	 
	PRIMARY KEY (user_revision,film_revision),
	FOREIGN KEY (user_revision) REFERENCES users(id),
	FOREIGN KEY (film_revision) REFERENCES films(id),
	INDEX(user_revision),
	INDEX(film_revision)
			   
);

-- промежуточная таблица для оценок фильма. 
DROP TABLE IF EXISTS scores;
CREATE TABLE scores (
	user_score BIGINT UNSIGNED NOT NULL,
	film_related BIGINT UNSIGNED NOT NULL,
	score TINYINT,
	
	PRIMARY KEY (user_score,film_related),
	FOREIGN KEY (user_score) REFERENCES users(id) on update cascade on delete cascade,
	FOREIGN KEY (film_related) REFERENCES films(id) on update cascade on delete cascade,
	
    INDEX(user_score),
	INDEX(film_related)
);

-- новостные посты от пользователей с статусом модерации поста. 
DROP TABLE IF EXISTS posts;
CREATE TABLE posts( 
		id SERIAL PRIMARY KEY,
		author_id BIGINT UNSIGNED NOT NULL,
		publish_date DATETIME DEFAULT NOW(),
		body TEXT,
		post_status ENUM ('front page', 'rejected', 'on moderation'),
			
		FOREIGN KEY (author_id) REFERENCES users(id),
		INDEX(author_id)
	

);

DROP TABLE IF EXISTS posts_for_films;
CREATE TABLE posts_for_films ( 
	post_id BIGINT UNSIGNED NOT NULL,
	films_id BIGINT UNSIGNED NOT NULL,
	PRIMARY KEY (post_id,films_id),
	FOREIGN KEY (post_id) references posts(id),
	FOREIGN KEY (films_id) references films(id)

); 


-- функция комментов к новостным постам. 
DROP TABLE IF EXISTS comments;
CREATE TABLE comments( 
	author_id BIGINT UNSIGNED NOT NULL,
	post_id BIGINT UNSIGNED NOT NULL, 
	comment_body TEXT,
	comment_time DATETIME DEFAULT NOW(),
	
	 PRIMARY KEY (author_id,post_id),
	 FOREIGN KEY (author_id) REFERENCES users(id) on delete cascade,
	 FOREIGN KEY (post_id) REFERENCES posts(id),
	 INDEX(post_id)	 
	 
);


DROP TABLE IF EXISTS profiles;
CREATE TABLE profiles( 
	user_id SERIAL PRIMARY KEY,
	user_name VARCHAR(20),
	date_of_birth DATE,
	home_town VARCHAR(30),
	gender ENUM ('mele', 'female'),
	
	FOREIGN KEY (user_id) REFERENCES users(id) on delete cascade,
	INDEX (user_id)

);

DROP TABLE IF EXISTS cinema;
CREATE TABLE cinema ( 
	id SERIAL PRIMARY KEY,
	name VARCHAR(30) NOT null,
	city VARCHAR(30) NOT NULL, 
	street VARCHAR(30) NOT NULL, 
	about TEXT
	
);

DROP TABLE IF EXISTS actors ;
CREATE TABLE actors (
	id SERIAL primary key, 
	full_name VARCHAR(50),
	date_of_birth DATE, 
	bio TEXT );

drop table if exists acotor_films; 
create table acotor_films( 
		actor_id BIGINT unsigned not null, 
		film_id BIGINT unsigned not null, 
		PRIMARY KEY (actor_id, film_id),
		foreign key (actor_id) references actors(id) on delete cascade on update cascade, 
		foreign key (film_id) references films(id) on delete cascade on update cascade
		
);

drop table if exists posts_for_actors;
create table posts_for_actors (
	post_id BIGINT unsigned not null, 
	actors_id BIGINT unsigned not null,
	
	
	primary key (actors_id,post_id), 
	foreign key (actors_id) references actors(id) on delete cascade on update cascade,
	foreign key (post_id) references posts(id) on delete cascade on update cascade
);


-- представление по обзорам фильмов которые были подтверждены модератором. 
CREATE OR REPLACE VIEW revisions_with_score AS 
SELECT
u.nickname,
r.body,
f.film_name,
s.score
FROM revisions AS r
	JOIN users AS u  ON r.user_revision = u.id 
	JOIN films AS f ON r.film_revision = f.id
	JOIN scores AS s ON  s.film_related =  f.id 
WHERE r.status = 'approved'
ORDER BY s.score DESC; 

-- представление по жанрам фильмов. 
CREATE OR REPLACE VIEW ganres_filmes AS  
SELECT 
f.film_name,
g.`type`,
s.score 

FROM films as f  
	JOIN genres_type as g on f.main_style = g.id
	JOIN scores as s on s.film_related = f.id 
	JOIN directors_films as df on df.id_film = f.id 
	JOIN directors as d on df.id_director = d.id

order by  g.`type`, s.score DESC;

-- представление скопировано из dbeaver  так как сходный код не сохранился. 
-- суть в выборке постов в которых указано кто делал посты, и на каких акторов + фильмы там есть ссылки. 
create or replace view `posts_test` as
select
    `f`.`film_name` as `Film name`,
    `ac`.`full_name` as `Actor`,
    `u`.`nickname` as `user nickname`,
    `p`.`body` as `News post`
from
    (((((`posts` `p`
join `posts_for_films` `pf` on
    ((`pf`.`films_id` = `p`.`id`)))
join `films` `f` on
    ((`f`.`id` = `pf`.`films_id`)))
join `posts_for_actors` `pa` on
    ((`pa`.`post_id` = `p`.`id`)))
join `actors` `ac` on
    ((`pa`.`actors_id` = `ac`.`id`)))
join `users` `u` on
    ((`u`.`id` = `p`.`author_id`)))
where
    (`p`.`post_status` = 'front page')
group by
    `p`.`body`;

-- тригер на подсчет среднего бала фильма при добавлении новых оценок от пользователей.
DELIMITER \\
drop trigger if exists `avg_score`  \\
CREATE TRIGGER `avg_score` AFTER INSERT ON `scores` FOR EACH ROW 
BEGIN 
	update films set film_total_score = (select avg(score) from scores where film_related = new.film_related) 
	where id = new.film_related;
END
\\ 
DELIMITER ; 


-- Пример функции рекомендации пользователю фильмов по вкусу. 
-- Логика: у каждого пользователя есть один любимый режиссер, по этому критерию подбираются пользователи  
-- у котрых такой же любимый режиссер как и  выбранного. После чего рассматриваются флиьмы которым эти пользователи 
-- хорошие оценки и выдаются изначальному пользователю. 

-- не работает в рамках функции ссылкается что выдача большой одной строки. Но без функции все работает. 
-- нужна помощь.  Пример без функции внизу. 

DELIMITER \\ 
DROP PROCEDURE IF EXISTS set_x \\
CREATE PROCEDURE set_x ( id INT)
BEGIN
  SET @x = id;
   select film_name 
	from films f 
	join scores s on s.film_related = f.id
	join users u on u.id = s.user_score
	where u.id = (select u.id 
		from users as u 
		join directors as d on u.favorite_director = d.id
		where u.favorite_director = (select favorite_director from users where id = @x) and u.id <> @x 
		order by rand() limit 1)  
	and s.score > 5 
	order by rand() limit 1;
 
END\\
DELIMITER ; 

-- call set_x(1);


-- как пример не функции это работает, и даже возвращает не больше чем 1 строку. 

/*
 * select film_name 
from films f 
	join scores s on s.film_related = f.id
	join users u on u.id = s.user_score
where u.id = (select u.id 
		from users as u 
		join directors as d on u.favorite_director = d.id
		where u.favorite_director = (select favorite_director from users where id = 1) and u.id <> 1 
		order by rand() limit 1)  and s.score > 5 
order by rand() limit 1;
 */









































