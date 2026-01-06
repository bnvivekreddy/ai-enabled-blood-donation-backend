<?php
/**
 * Database Connection Configuration
 * LifeFlow Blood Donation App
 */

// Database credentials
define('DB_HOST', 'localhost');
define('DB_NAME', 'blood_donation');
define('DB_USER', 'root');
define('DB_PASS', '');

// Response headers
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

/**
 * Get database connection
 */
function getConnection()
{
    try {
        $conn = new PDO(
            "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
            DB_USER,
            DB_PASS,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false
            ]
        );
        return $conn;
    } catch (PDOException $e) {
        sendResponse(false, "Database connection failed: " . $e->getMessage(), null, 500);
        exit;
    }
}

/**
 * Send JSON response
 */
function sendResponse($success, $message, $data = null, $statusCode = 200)
{
    http_response_code($statusCode);
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data' => $data
    ]);
    exit;
}

/**
 * Get POST data as JSON
 */
function getPostData()
{
    $json = file_get_contents('php://input');
    return json_decode($json, true);
}

/**
 * Validate required fields
 */
function validateRequired($data, $fields)
{
    $missing = [];
    foreach ($fields as $field) {
        if (!isset($data[$field])) {
            $missing[] = $field;
            continue;
        }

        $value = trim((string) $data[$field]);
        if ($value === '') { // Only fails if strictly empty string
            $missing[] = $field;
        }
    }
    return $missing;
}

/**
 * Sanitize input
 */
function sanitize($input)
{
    return htmlspecialchars(strip_tags(trim($input)));
}
?>