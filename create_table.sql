-- =============================================================================
-- [Thực hành] Tạo bảng trên MySQL Workbench
-- Mục tiêu: Luyện tập các thao tác tạo bảng Class và Teacher trong schema student-management
-- =============================================================================

-- Bước 1: Tạo và sử dụng CSDL student-management (nếu chưa có)
CREATE DATABASE IF NOT EXISTS `student-management`;
USE `student-management`;

-- Bước 2: Tạo bảng Class với các trường id, name
CREATE TABLE IF NOT EXISTS `Class` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NULL,
    PRIMARY KEY (`id`)
);

-- Bước 3 & 4: Tạo bảng Teacher với các trường id, name, age, country
CREATE TABLE IF NOT EXISTS `Teacher` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NULL,
    `age` INT NULL,
    `country` VARCHAR(50) NULL,
    PRIMARY KEY (`id`)
);

-- Kiểm tra cấu trúc các bảng vừa tạo
DESCRIBE `Class`;
DESCRIBE `Teacher`;
