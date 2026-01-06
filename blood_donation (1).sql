-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 28, 2025 at 11:35 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `blood_donation`
--

-- --------------------------------------------------------

--
-- Stand-in structure for view `active_emergency_requests`
-- (See below for the actual view)
--
CREATE TABLE `active_emergency_requests` (
`request_id` int(11)
,`blood_group` enum('A+','A-','B+','B-','O+','O-','AB+','AB-')
,`units_required` int(11)
,`urgency` enum('critical','urgent','normal')
,`patient_name` varchar(255)
,`patient_phone` varchar(15)
,`hospital_name` varchar(255)
,`latitude` decimal(10,8)
,`longitude` decimal(11,8)
,`created_at` timestamp
,`minutes_ago` bigint(21)
);

-- --------------------------------------------------------

--
-- Table structure for table `activity_log`
--

CREATE TABLE `activity_log` (
  `log_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `action` varchar(100) NOT NULL,
  `entity_type` varchar(50) DEFAULT NULL,
  `entity_id` int(11) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ai_matches`
--

CREATE TABLE `ai_matches` (
  `match_id` int(11) NOT NULL,
  `request_id` int(11) NOT NULL,
  `donor_id` int(11) NOT NULL,
  `match_score` decimal(5,2) NOT NULL,
  `distance_km` decimal(8,2) NOT NULL,
  `compatibility_score` decimal(5,2) NOT NULL,
  `availability_score` decimal(5,2) NOT NULL,
  `match_status` enum('suggested','notified','accepted','declined','expired') DEFAULT 'suggested',
  `notified_at` timestamp NULL DEFAULT NULL,
  `responded_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ai_predictions`
--

CREATE TABLE `ai_predictions` (
  `prediction_id` int(11) NOT NULL,
  `hospital_id` int(11) NOT NULL,
  `blood_group` enum('A+','A-','B+','B-','O+','O-','AB+','AB-') NOT NULL,
  `current_stock` int(11) NOT NULL,
  `predicted_demand` int(11) NOT NULL,
  `shortage_probability` decimal(5,2) NOT NULL,
  `days_until_shortage` int(11) DEFAULT NULL,
  `recommended_units` int(11) NOT NULL,
  `prediction_date` date NOT NULL,
  `confidence_score` decimal(5,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `analytics_data`
--

CREATE TABLE `analytics_data` (
  `analytics_id` int(11) NOT NULL,
  `hospital_id` int(11) NOT NULL,
  `metric_type` enum('donations','requests','stock','shortage','response_time') NOT NULL,
  `metric_value` decimal(10,2) NOT NULL,
  `date` date NOT NULL,
  `hour` int(11) DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `badges_earned`
--

CREATE TABLE `badges_earned` (
  `badge_id` int(11) NOT NULL,
  `donor_id` int(11) NOT NULL,
  `badge_name` varchar(100) NOT NULL,
  `badge_type` enum('first_time','milestone','streak','special','platinum') NOT NULL,
  `badge_icon` varchar(50) NOT NULL,
  `description` text NOT NULL,
  `earned_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `blood_requests`
--

CREATE TABLE `blood_requests` (
  `request_id` int(11) NOT NULL,
  `patient_id` int(11) NOT NULL,
  `hospital_id` int(11) DEFAULT NULL,
  `blood_group` enum('A+','A-','B+','B-','O+','O-','AB+','AB-') NOT NULL,
  `units_required` int(11) NOT NULL,
  `urgency` enum('critical','urgent','normal') NOT NULL,
  `request_type` enum('emergency','regular') DEFAULT 'regular',
  `status` enum('pending','matching','matched','in_progress','completed','cancelled','expired') DEFAULT 'pending',
  `reason` text DEFAULT NULL,
  `required_by` datetime DEFAULT NULL,
  `latitude` decimal(10,8) NOT NULL,
  `longitude` decimal(11,8) NOT NULL,
  `hospital_name` varchar(255) NOT NULL,
  `hospital_address` text NOT NULL,
  `matched_donor_id` int(11) DEFAULT NULL,
  `accepted_at` timestamp NULL DEFAULT NULL,
  `completed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `blood_stock`
--

CREATE TABLE `blood_stock` (
  `stock_id` int(11) NOT NULL,
  `hospital_id` int(11) NOT NULL,
  `blood_group` enum('A+','A-','B+','B-','O+','O-','AB+','AB-') NOT NULL,
  `units_available` int(11) NOT NULL DEFAULT 0,
  `units_reserved` int(11) DEFAULT 0,
  `minimum_threshold` int(11) DEFAULT 5,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `status` enum('good','low','critical') GENERATED ALWAYS AS (case when `units_available` >= `minimum_threshold` * 2 then 'good' when `units_available` >= `minimum_threshold` then 'low' else 'critical' end) VIRTUAL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `blood_stock_status`
-- (See below for the actual view)
--
CREATE TABLE `blood_stock_status` (
`hospital_id` int(11)
,`hospital_name` varchar(255)
,`city` varchar(100)
,`blood_group` enum('A+','A-','B+','B-','O+','O-','AB+','AB-')
,`units_available` int(11)
,`minimum_threshold` int(11)
,`stock_status` varchar(8)
,`last_updated` timestamp
);

-- --------------------------------------------------------

--
-- Table structure for table `donations`
--

CREATE TABLE `donations` (
  `donation_id` int(11) NOT NULL,
  `donor_id` int(11) NOT NULL,
  `request_id` int(11) DEFAULT NULL,
  `hospital_id` int(11) NOT NULL,
  `blood_group` enum('A+','A-','B+','B-','O+','O-','AB+','AB-') NOT NULL,
  `units_donated` decimal(4,2) NOT NULL DEFAULT 1.00,
  `donation_date` date NOT NULL,
  `donation_time` time NOT NULL,
  `donation_type` enum('whole_blood','plasma','platelets','power_red') DEFAULT 'whole_blood',
  `status` enum('scheduled','completed','cancelled','no_show') DEFAULT 'completed',
  `hemoglobin_level` decimal(4,2) DEFAULT NULL,
  `blood_pressure` varchar(20) DEFAULT NULL,
  `temperature` decimal(4,2) DEFAULT NULL,
  `weight` decimal(5,2) DEFAULT NULL,
  `medical_notes` text DEFAULT NULL,
  `rewards_points` int(11) DEFAULT 100,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `donations`
--
DELIMITER $$
CREATE TRIGGER `after_donation_insert` AFTER INSERT ON `donations` FOR EACH ROW BEGIN
    IF NEW.status = 'completed' THEN
        UPDATE donor_profiles 
        SET total_donations = total_donations + 1,
            lives_saved = lives_saved + 1,
            last_donation_date = NEW.donation_date,
            next_eligible_date = DATE_ADD(NEW.donation_date, INTERVAL 90 DAY)
        WHERE donor_id = NEW.donor_id;
        
        UPDATE donor_rewards
        SET total_points = total_points + NEW.rewards_points,
            lifetime_donations = lifetime_donations + 1
        WHERE donor_id = NEW.donor_id;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `donor_profiles`
--

CREATE TABLE `donor_profiles` (
  `donor_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `blood_group` enum('A+','A-','B+','B-','O+','O-','AB+','AB-') NOT NULL,
  `gender` enum('Male','Female','Other') NOT NULL,
  `age` int(11) NOT NULL,
  `phone` varchar(15) NOT NULL,
  `weight` decimal(5,2) DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `state` varchar(100) DEFAULT NULL,
  `pincode` varchar(10) DEFAULT NULL,
  `is_eligible` tinyint(1) DEFAULT 1,
  `last_donation_date` date DEFAULT NULL,
  `next_eligible_date` date DEFAULT NULL,
  `total_donations` int(11) DEFAULT 0,
  `lives_saved` int(11) DEFAULT 0,
  `profile_photo` varchar(255) DEFAULT NULL,
  `emergency_contact` varchar(15) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `donor_rewards`
--

CREATE TABLE `donor_rewards` (
  `reward_id` int(11) NOT NULL,
  `donor_id` int(11) NOT NULL,
  `total_points` int(11) DEFAULT 0,
  `current_level` int(11) DEFAULT 1,
  `current_streak` int(11) DEFAULT 0,
  `longest_streak` int(11) DEFAULT 0,
  `total_badges` int(11) DEFAULT 0,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `eligibility_checks`
--

CREATE TABLE `eligibility_checks` (
  `check_id` int(11) NOT NULL,
  `donor_id` int(11) NOT NULL,
  `check_date` date NOT NULL,
  `is_eligible` tinyint(1) NOT NULL,
  `hemoglobin` decimal(4,2) DEFAULT NULL,
  `blood_pressure` varchar(20) DEFAULT NULL,
  `weight` decimal(5,2) DEFAULT NULL,
  `temperature` decimal(4,2) DEFAULT NULL,
  `medical_conditions` text DEFAULT NULL,
  `medications` text DEFAULT NULL,
  `travel_history` text DEFAULT NULL,
  `disqualification_reason` text DEFAULT NULL,
  `checked_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `emergency_contacts`
--

CREATE TABLE `emergency_contacts` (
  `contact_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `contact_name` varchar(255) NOT NULL,
  `relationship` varchar(100) NOT NULL,
  `phone` varchar(15) NOT NULL,
  `is_primary` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `hospital_profiles`
--

CREATE TABLE `hospital_profiles` (
  `hospital_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `hospital_name` varchar(255) NOT NULL,
  `registration_number` varchar(100) NOT NULL,
  `license_number` varchar(100) NOT NULL,
  `license_expiry_date` date NOT NULL,
  `blood_bank_license` varchar(100) DEFAULT NULL,
  `contact_person` varchar(255) NOT NULL,
  `contact_email` varchar(255) NOT NULL,
  `contact_phone` varchar(15) NOT NULL,
  `latitude` decimal(10,8) NOT NULL,
  `longitude` decimal(11,8) NOT NULL,
  `address` text NOT NULL,
  `city` varchar(100) NOT NULL,
  `state` varchar(100) NOT NULL,
  `pincode` varchar(10) NOT NULL,
  `website` varchar(255) DEFAULT NULL,
  `operating_hours` varchar(255) DEFAULT NULL,
  `has_blood_bank` tinyint(1) DEFAULT 1,
  `verification_status` enum('pending','verified','rejected') DEFAULT 'pending',
  `verified_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `leaderboard`
--

CREATE TABLE `leaderboard` (
  `rank_id` int(11) NOT NULL,
  `donor_id` int(11) NOT NULL,
  `total_donations` int(11) DEFAULT 0,
  `total_points` int(11) DEFAULT 0,
  `month_year` varchar(7) NOT NULL,
  `rank_position` int(11) NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `notification_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `type` enum('emergency','eligible','stock_alert','success','info','reminder') NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `related_id` int(11) DEFAULT NULL,
  `related_type` enum('request','donation','match','stock') DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `is_sent` tinyint(1) DEFAULT 0,
  `priority` enum('high','medium','low') DEFAULT 'medium',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `read_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notification_preferences`
--

CREATE TABLE `notification_preferences` (
  `preference_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `emergency_alerts` tinyint(1) DEFAULT 1,
  `nearby_requests` tinyint(1) DEFAULT 1,
  `eligibility_reminders` tinyint(1) DEFAULT 1,
  `stock_alerts` tinyint(1) DEFAULT 0,
  `donation_milestones` tinyint(1) DEFAULT 1,
  `health_tips` tinyint(1) DEFAULT 1,
  `email_notifications` tinyint(1) DEFAULT 1,
  `sms_notifications` tinyint(1) DEFAULT 1,
  `push_notifications` tinyint(1) DEFAULT 1,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `patient_profiles`
--

CREATE TABLE `patient_profiles` (
  `patient_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `blood_group` enum('A+','A-','B+','B-','O+','O-','AB+','AB-') NOT NULL,
  `gender` enum('Male','Female','Other') NOT NULL,
  `age` int(11) NOT NULL,
  `phone` varchar(15) NOT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `state` varchar(100) DEFAULT NULL,
  `pincode` varchar(10) DEFAULT NULL,
  `emergency_contact` varchar(15) DEFAULT NULL,
  `medical_history` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_transactions`
--

CREATE TABLE `stock_transactions` (
  `transaction_id` int(11) NOT NULL,
  `hospital_id` int(11) NOT NULL,
  `blood_group` enum('A+','A-','B+','B-','O+','O-','AB+','AB-') NOT NULL,
  `transaction_type` enum('received','issued','expired','adjustment') NOT NULL,
  `units` int(11) NOT NULL,
  `reference_id` int(11) DEFAULT NULL,
  `reference_type` enum('donation','request','transfer','disposal') DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `top_donors`
-- (See below for the actual view)
--
CREATE TABLE `top_donors` (
`donor_id` int(11)
,`full_name` varchar(255)
,`blood_group` enum('A+','A-','B+','B-','O+','O-','AB+','AB-')
,`city` varchar(100)
,`total_points` int(11)
,`current_level` int(11)
,`total_badges` int(11)
,`total_donations` int(11)
,`lives_saved` int(11)
);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('donor','patient','hospital') NOT NULL,
  `status` enum('active','inactive','suspended') DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `last_login` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `users`
--
DELIMITER $$
CREATE TRIGGER `after_user_insert` AFTER INSERT ON `users` FOR EACH ROW BEGIN
    INSERT INTO notification_preferences (user_id) VALUES (NEW.user_id);
    INSERT INTO user_settings (user_id) VALUES (NEW.user_id);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `user_settings`
--

CREATE TABLE `user_settings` (
  `setting_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `language` varchar(10) DEFAULT 'en',
  `theme` enum('light','dark','auto') DEFAULT 'light',
  `location_sharing` tinyint(1) DEFAULT 1,
  `emergency_mode` tinyint(1) DEFAULT 1,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure for view `active_emergency_requests`
--
DROP TABLE IF EXISTS `active_emergency_requests`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `active_emergency_requests`  AS SELECT `r`.`request_id` AS `request_id`, `r`.`blood_group` AS `blood_group`, `r`.`units_required` AS `units_required`, `r`.`urgency` AS `urgency`, `p`.`full_name` AS `patient_name`, `p`.`phone` AS `patient_phone`, `r`.`hospital_name` AS `hospital_name`, `r`.`latitude` AS `latitude`, `r`.`longitude` AS `longitude`, `r`.`created_at` AS `created_at`, timestampdiff(MINUTE,`r`.`created_at`,current_timestamp()) AS `minutes_ago` FROM (`blood_requests` `r` join `patient_profiles` `p` on(`r`.`patient_id` = `p`.`patient_id`)) WHERE `r`.`status` in ('pending','matching','matched') AND `r`.`request_type` = 'emergency' ORDER BY `r`.`urgency` DESC, `r`.`created_at` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `blood_stock_status`
--
DROP TABLE IF EXISTS `blood_stock_status`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `blood_stock_status`  AS SELECT `h`.`hospital_id` AS `hospital_id`, `h`.`hospital_name` AS `hospital_name`, `h`.`city` AS `city`, `bs`.`blood_group` AS `blood_group`, `bs`.`units_available` AS `units_available`, `bs`.`minimum_threshold` AS `minimum_threshold`, CASE WHEN `bs`.`units_available` >= `bs`.`minimum_threshold` * 2 THEN 'Good' WHEN `bs`.`units_available` >= `bs`.`minimum_threshold` THEN 'Low' ELSE 'Critical' END AS `stock_status`, `bs`.`last_updated` AS `last_updated` FROM (`blood_stock` `bs` join `hospital_profiles` `h` on(`bs`.`hospital_id` = `h`.`hospital_id`)) ORDER BY `h`.`hospital_name` ASC, `bs`.`blood_group` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `top_donors`
--
DROP TABLE IF EXISTS `top_donors`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `top_donors`  AS SELECT `d`.`donor_id` AS `donor_id`, `d`.`full_name` AS `full_name`, `d`.`blood_group` AS `blood_group`, `d`.`city` AS `city`, `dr`.`total_points` AS `total_points`, `dr`.`current_level` AS `current_level`, `dr`.`total_badges` AS `total_badges`, `d`.`total_donations` AS `total_donations`, `d`.`lives_saved` AS `lives_saved` FROM (`donor_profiles` `d` join `donor_rewards` `dr` on(`d`.`donor_id` = `dr`.`donor_id`)) WHERE `d`.`is_eligible` = 1 ORDER BY `dr`.`total_points` DESC LIMIT 0, 100 ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `activity_log`
--
ALTER TABLE `activity_log`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `idx_user` (`user_id`),
  ADD KEY `idx_action` (`action`),
  ADD KEY `idx_created` (`created_at`);

--
-- Indexes for table `ai_matches`
--
ALTER TABLE `ai_matches`
  ADD PRIMARY KEY (`match_id`),
  ADD KEY `idx_request` (`request_id`),
  ADD KEY `idx_donor` (`donor_id`),
  ADD KEY `idx_score` (`match_score`);

--
-- Indexes for table `ai_predictions`
--
ALTER TABLE `ai_predictions`
  ADD PRIMARY KEY (`prediction_id`),
  ADD KEY `idx_hospital` (`hospital_id`),
  ADD KEY `idx_date` (`prediction_date`);

--
-- Indexes for table `analytics_data`
--
ALTER TABLE `analytics_data`
  ADD PRIMARY KEY (`analytics_id`),
  ADD KEY `idx_hospital_date` (`hospital_id`,`date`),
  ADD KEY `idx_type` (`metric_type`);

--
-- Indexes for table `badges_earned`
--
ALTER TABLE `badges_earned`
  ADD PRIMARY KEY (`badge_id`),
  ADD KEY `idx_donor` (`donor_id`),
  ADD KEY `idx_type` (`badge_type`);

--
-- Indexes for table `blood_requests`
--
ALTER TABLE `blood_requests`
  ADD PRIMARY KEY (`request_id`),
  ADD KEY `patient_id` (`patient_id`),
  ADD KEY `hospital_id` (`hospital_id`),
  ADD KEY `matched_donor_id` (`matched_donor_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_blood_group` (`blood_group`),
  ADD KEY `idx_urgency` (`urgency`),
  ADD KEY `idx_created` (`created_at`);

--
-- Indexes for table `blood_stock`
--
ALTER TABLE `blood_stock`
  ADD PRIMARY KEY (`stock_id`),
  ADD UNIQUE KEY `unique_hospital_blood` (`hospital_id`,`blood_group`),
  ADD KEY `idx_blood_group` (`blood_group`),
  ADD KEY `idx_status_computed` (`status`);

--
-- Indexes for table `donations`
--
ALTER TABLE `donations`
  ADD PRIMARY KEY (`donation_id`),
  ADD KEY `request_id` (`request_id`),
  ADD KEY `idx_donor` (`donor_id`),
  ADD KEY `idx_date` (`donation_date`),
  ADD KEY `idx_hospital` (`hospital_id`);

--
-- Indexes for table `donor_profiles`
--
ALTER TABLE `donor_profiles`
  ADD PRIMARY KEY (`donor_id`),
  ADD UNIQUE KEY `user_id` (`user_id`),
  ADD KEY `idx_blood_group` (`blood_group`),
  ADD KEY `idx_location` (`latitude`,`longitude`),
  ADD KEY `idx_eligibility` (`is_eligible`);

--
-- Indexes for table `donor_rewards`
--
ALTER TABLE `donor_rewards`
  ADD PRIMARY KEY (`reward_id`),
  ADD KEY `donor_id` (`donor_id`),
  ADD KEY `idx_points` (`total_points`),
  ADD KEY `idx_level` (`current_level`);

--
-- Indexes for table `eligibility_checks`
--
ALTER TABLE `eligibility_checks`
  ADD PRIMARY KEY (`check_id`),
  ADD KEY `checked_by` (`checked_by`),
  ADD KEY `idx_donor` (`donor_id`),
  ADD KEY `idx_date` (`check_date`);

--
-- Indexes for table `emergency_contacts`
--
ALTER TABLE `emergency_contacts`
  ADD PRIMARY KEY (`contact_id`),
  ADD KEY `idx_user` (`user_id`);

--
-- Indexes for table `hospital_profiles`
--
ALTER TABLE `hospital_profiles`
  ADD PRIMARY KEY (`hospital_id`),
  ADD UNIQUE KEY `user_id` (`user_id`),
  ADD UNIQUE KEY `registration_number` (`registration_number`),
  ADD UNIQUE KEY `license_number` (`license_number`),
  ADD KEY `idx_location` (`latitude`,`longitude`),
  ADD KEY `idx_verification` (`verification_status`);

--
-- Indexes for table `leaderboard`
--
ALTER TABLE `leaderboard`
  ADD PRIMARY KEY (`rank_id`),
  ADD UNIQUE KEY `unique_donor_month` (`donor_id`,`month_year`),
  ADD KEY `idx_month` (`month_year`),
  ADD KEY `idx_rank` (`rank_position`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `idx_user` (`user_id`),
  ADD KEY `idx_read` (`is_read`),
  ADD KEY `idx_created` (`created_at`);

--
-- Indexes for table `notification_preferences`
--
ALTER TABLE `notification_preferences`
  ADD PRIMARY KEY (`preference_id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `patient_profiles`
--
ALTER TABLE `patient_profiles`
  ADD PRIMARY KEY (`patient_id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `stock_transactions`
--
ALTER TABLE `stock_transactions`
  ADD PRIMARY KEY (`transaction_id`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `idx_hospital` (`hospital_id`),
  ADD KEY `idx_date` (`created_at`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_role` (`role`);

--
-- Indexes for table `user_settings`
--
ALTER TABLE `user_settings`
  ADD PRIMARY KEY (`setting_id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `activity_log`
--
ALTER TABLE `activity_log`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ai_matches`
--
ALTER TABLE `ai_matches`
  MODIFY `match_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ai_predictions`
--
ALTER TABLE `ai_predictions`
  MODIFY `prediction_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `analytics_data`
--
ALTER TABLE `analytics_data`
  MODIFY `analytics_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `badges_earned`
--
ALTER TABLE `badges_earned`
  MODIFY `badge_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `blood_requests`
--
ALTER TABLE `blood_requests`
  MODIFY `request_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `blood_stock`
--
ALTER TABLE `blood_stock`
  MODIFY `stock_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `donations`
--
ALTER TABLE `donations`
  MODIFY `donation_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `donor_profiles`
--
ALTER TABLE `donor_profiles`
  MODIFY `donor_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `donor_rewards`
--
ALTER TABLE `donor_rewards`
  MODIFY `reward_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `eligibility_checks`
--
ALTER TABLE `eligibility_checks`
  MODIFY `check_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `emergency_contacts`
--
ALTER TABLE `emergency_contacts`
  MODIFY `contact_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `hospital_profiles`
--
ALTER TABLE `hospital_profiles`
  MODIFY `hospital_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `leaderboard`
--
ALTER TABLE `leaderboard`
  MODIFY `rank_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `notification_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notification_preferences`
--
ALTER TABLE `notification_preferences`
  MODIFY `preference_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `patient_profiles`
--
ALTER TABLE `patient_profiles`
  MODIFY `patient_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_transactions`
--
ALTER TABLE `stock_transactions`
  MODIFY `transaction_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_settings`
--
ALTER TABLE `user_settings`
  MODIFY `setting_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `activity_log`
--
ALTER TABLE `activity_log`
  ADD CONSTRAINT `activity_log_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `ai_matches`
--
ALTER TABLE `ai_matches`
  ADD CONSTRAINT `ai_matches_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `blood_requests` (`request_id`),
  ADD CONSTRAINT `ai_matches_ibfk_2` FOREIGN KEY (`donor_id`) REFERENCES `donor_profiles` (`donor_id`);

--
-- Constraints for table `ai_predictions`
--
ALTER TABLE `ai_predictions`
  ADD CONSTRAINT `ai_predictions_ibfk_1` FOREIGN KEY (`hospital_id`) REFERENCES `hospital_profiles` (`hospital_id`);

--
-- Constraints for table `analytics_data`
--
ALTER TABLE `analytics_data`
  ADD CONSTRAINT `analytics_data_ibfk_1` FOREIGN KEY (`hospital_id`) REFERENCES `hospital_profiles` (`hospital_id`);

--
-- Constraints for table `badges_earned`
--
ALTER TABLE `badges_earned`
  ADD CONSTRAINT `badges_earned_ibfk_1` FOREIGN KEY (`donor_id`) REFERENCES `donor_profiles` (`donor_id`);

--
-- Constraints for table `blood_requests`
--
ALTER TABLE `blood_requests`
  ADD CONSTRAINT `blood_requests_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patient_profiles` (`patient_id`),
  ADD CONSTRAINT `blood_requests_ibfk_2` FOREIGN KEY (`hospital_id`) REFERENCES `hospital_profiles` (`hospital_id`),
  ADD CONSTRAINT `blood_requests_ibfk_3` FOREIGN KEY (`matched_donor_id`) REFERENCES `donor_profiles` (`donor_id`);

--
-- Constraints for table `blood_stock`
--
ALTER TABLE `blood_stock`
  ADD CONSTRAINT `blood_stock_ibfk_1` FOREIGN KEY (`hospital_id`) REFERENCES `hospital_profiles` (`hospital_id`);

--
-- Constraints for table `donations`
--
ALTER TABLE `donations`
  ADD CONSTRAINT `donations_ibfk_1` FOREIGN KEY (`donor_id`) REFERENCES `donor_profiles` (`donor_id`),
  ADD CONSTRAINT `donations_ibfk_2` FOREIGN KEY (`request_id`) REFERENCES `blood_requests` (`request_id`),
  ADD CONSTRAINT `donations_ibfk_3` FOREIGN KEY (`hospital_id`) REFERENCES `hospital_profiles` (`hospital_id`);

--
-- Constraints for table `donor_profiles`
--
ALTER TABLE `donor_profiles`
  ADD CONSTRAINT `donor_profiles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `donor_rewards`
--
ALTER TABLE `donor_rewards`
  ADD CONSTRAINT `donor_rewards_ibfk_1` FOREIGN KEY (`donor_id`) REFERENCES `donor_profiles` (`donor_id`);

--
-- Constraints for table `eligibility_checks`
--
ALTER TABLE `eligibility_checks`
  ADD CONSTRAINT `eligibility_checks_ibfk_1` FOREIGN KEY (`donor_id`) REFERENCES `donor_profiles` (`donor_id`),
  ADD CONSTRAINT `eligibility_checks_ibfk_2` FOREIGN KEY (`checked_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `emergency_contacts`
--
ALTER TABLE `emergency_contacts`
  ADD CONSTRAINT `emergency_contacts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `hospital_profiles`
--
ALTER TABLE `hospital_profiles`
  ADD CONSTRAINT `hospital_profiles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `leaderboard`
--
ALTER TABLE `leaderboard`
  ADD CONSTRAINT `leaderboard_ibfk_1` FOREIGN KEY (`donor_id`) REFERENCES `donor_profiles` (`donor_id`);

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `notification_preferences`
--
ALTER TABLE `notification_preferences`
  ADD CONSTRAINT `notification_preferences_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `patient_profiles`
--
ALTER TABLE `patient_profiles`
  ADD CONSTRAINT `patient_profiles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `stock_transactions`
--
ALTER TABLE `stock_transactions`
  ADD CONSTRAINT `stock_transactions_ibfk_1` FOREIGN KEY (`hospital_id`) REFERENCES `hospital_profiles` (`hospital_id`),
  ADD CONSTRAINT `stock_transactions_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `user_settings`
--
ALTER TABLE `user_settings`
  ADD CONSTRAINT `user_settings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
