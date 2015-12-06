CREATE TABLE `comments` (
  `thread` int,
  `no` int,
  `vpos` int,
  `date` int,
  `mail`varchar(100),
  `user_id` varchar(100),
  `premium` varchar(5),
  `anonymity` varchar(5),
  `leaf` varchar(5),
  `fork` varchar(5),
  `deleted` varchar(5),
  `content` varchar(255),
  KEY `comments_thread` (`thread`),
  KEY `comments_no` (`no`),
  KEY `comments_vpos` (`vpos`),
  KEY `comments_date` (`date`),
  KEY `comments_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;