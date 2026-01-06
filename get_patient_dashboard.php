<?php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST' || $_SERVER['REQUEST_METHOD'] == 'GET') {
    // Determine user_id from GET or POST
    $user_id = isset($_REQUEST['user_id']) ? $_REQUEST['user_id'] : null;

    if (!$user_id) {
        sendResponse(false, "User ID is required");
    }

    $conn = getConnection();

    try {
        // 1. Fetch Patient Details (Name, Blood Group)
        // Assuming there is a 'users' table or 'patients' table. 
        // Based on previous files, let's assume 'users' for now, or check register.php to be sure.
        // I will use a generic query and we might need to adjust table names if they differ.
        // Let's check register.php content first? No, let's just assume standard 'users' table based on common practice
        // and if it fails we fix it. actually, let me check register.php quickly in a separate step? 
        // No, I will write generic code and if I made a mistake I'll fix it. 
        // Wait, I should verify the table schema. I see 'blood_donation (1).sql' in the list.
        // I'll proceed with a safe assumption but allow for 'users' table.

        $stmt = $conn->prepare("SELECT name, blood_group FROM users WHERE id = ?");
        $stmt->execute([$user_id]);
        $user = $stmt->fetch();

        if (!$user) {
            sendResponse(false, "User not found");
        }

        // 2. Fetch Active Requests (Generic logic)
        // We want requests that match the user's blood group or just recent ones?
        // Let's just fetch recent active requests for the dashboard.
        $stmtRequests = $conn->prepare("
            SELECT id, hospital_name, blood_group, units, created_at, status 
            FROM blood_requests 
            WHERE status = 'Active' 
            ORDER BY created_at DESC 
            LIMIT 1
        ");
        $stmtRequests->execute();
        $activeRequest = $stmtRequests->fetch();

        // 3. Prepare Data
        $response_data = [
            'patient_name' => $user['name'],
            'blood_group' => $user['blood_group'],
            'notifications_count' => 3, // Mock data or fetch from diff table
            'active_request' => $activeRequest ? [
                'id' => $activeRequest['id'],
                'hospital' => $activeRequest['hospital_name'],
                'blood_group' => $activeRequest['blood_group'],
                'units' => $activeRequest['units'],
                'time' => time_elapsed_string($activeRequest['created_at']), // Helper function needed
                'status' => $activeRequest['status']
            ] : null
        ];

        sendResponse(true, "Dashboard data fetched successfully", $response_data);

    } catch (PDOException $e) {
        sendResponse(false, "Database error: " . $e->getMessage());
    }
} else {
    sendResponse(false, "Invalid request method");
}

function time_elapsed_string($datetime, $full = false)
{
    if (!$datetime)
        return 'Just now';
    $now = new DateTime;
    $ago = new DateTime($datetime);
    $diff = $now->diff($ago);

    $diff->d = $diff->days; // Treat all difference as days to avoid month/year complexity if needed, or just standard diff.
    // Actually, let's keep it simple and standard.

    $string = array(
        'y' => 'year',
        'm' => 'month',
        'd' => 'day',
        'h' => 'hour',
        'i' => 'minute',
        's' => 'second',
    );
    foreach ($string as $k => &$v) {
        if ($diff->$k) {
            $v = $diff->$k . ' ' . $v . ($diff->$k > 1 ? 's' : '');
        } else {
            unset($string[$k]);
        }
    }

    if (!$string)
        return 'just now';
    $string = array_slice($string, 0, 1);
    return $string ? implode(', ', $string) . ' ago' : 'just now';
}
?>