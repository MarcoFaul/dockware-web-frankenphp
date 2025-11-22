<?php
/**
 * FrankenPHP Worker Mode Bootstrap
 * 
 * This file handles requests in worker mode for optimal performance.
 * It stays in memory and processes multiple requests without reinitializing PHP.
 */

declare(strict_types=1);

// Initialize worker mode
if (!function_exists('frankenphp_handle_request')) {
    // Fallback for non-FrankenPHP environments
    function frankenphp_handle_request(callable $handler): void {
        $handler();
    }
}

// Set memory limit for worker
ini_set('memory_limit', '512M');

// Configure error handling
error_reporting(E_ALL);
ini_set('display_errors', '1');
ini_set('log_errors', '1');
ini_set('error_log', '/var/log/php/frankenphp_worker_errors.log');

// Set timezone
if (getenv('TZ')) {
    date_default_timezone_set(getenv('TZ'));
}

// Worker request handler
frankenphp_handle_request(function (): void {
    try {
        // Get the request URI
        $requestUri = $_SERVER['REQUEST_URI'] ?? '/';
        $scriptName = $_SERVER['SCRIPT_NAME'] ?? '';
        $documentRoot = $_SERVER['DOCUMENT_ROOT'] ?? '/var/www/html/public';
        
        // Parse the request
        $parsedUrl = parse_url($requestUri);
        $path = $parsedUrl['path'] ?? '/';
        
        // Remove script name from path if present
        if ($scriptName && strpos($path, $scriptName) === 0) {
            $path = substr($path, strlen($scriptName));
        }
        
        // Determine the file to execute
        $filePath = $documentRoot . $path;
        
        // If it's a directory, try to find index.php
        if (is_dir($filePath)) {
            $indexFile = rtrim($filePath, '/') . '/index.php';
            if (file_exists($indexFile)) {
                $filePath = $indexFile;
            }
        }
        
        // If the file doesn't exist and it's not a PHP file, try routing through index.php
        if (!file_exists($filePath) || !is_file($filePath)) {
            $indexFile = $documentRoot . '/index.php';
            if (file_exists($indexFile)) {
                $filePath = $indexFile;
            }
        }
        
        // Security check: ensure we're still within document root
        $realFilePath = realpath($filePath);
        $realDocRoot = realpath($documentRoot);
        
        if (!$realFilePath || !$realDocRoot || strpos($realFilePath, $realDocRoot) !== 0) {
            http_response_code(404);
            echo "404 Not Found";
            return;
        }
        
        // Check if it's a PHP file
        if (pathinfo($filePath, PATHINFO_EXTENSION) === 'php') {
            // Set up environment for the PHP script
            $_SERVER['SCRIPT_FILENAME'] = $filePath;
            $_SERVER['PHP_SELF'] = str_replace($documentRoot, '', $filePath);
            
            // Clear any previous output
            if (ob_get_level()) {
                ob_clean();
            }
            
            // Start output buffering to capture any output
            ob_start();
            
            // Include the PHP file
            include $filePath;
            
            // Send the buffered output
            $output = ob_get_clean();
            if ($output !== false) {
                echo $output;
            }
        } else {
            // For non-PHP files, we shouldn't handle them in worker mode
            // This should be handled by Caddy's file server
            http_response_code(404);
            echo "File not found or not a PHP file";
        }
        
    } catch (Throwable $e) {
        // Log the error
        error_log('FrankenPHP Worker Error: ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine());
        
        // Send error response
        http_response_code(500);
        echo "Internal Server Error";
        
        // If we're in development mode, show the error
        if (getenv('APP_ENV') === 'development' || getenv('DEBUG') === '1') {
            echo "\n\nDEBUG INFO:\n";
            echo "Error: " . $e->getMessage() . "\n";
            echo "File: " . $e->getFile() . "\n";
            echo "Line: " . $e->getLine() . "\n";
            echo "Trace:\n" . $e->getTraceAsString();
        }
    } finally {
        // Clean up for next request
        if (function_exists('gc_collect_cycles')) {
            gc_collect_cycles();
        }
        
        // Reset any global state that might affect next requests
        $_GET = [];
        $_POST = [];
        $_REQUEST = [];
        $_FILES = [];
        $_SESSION = $_SESSION ?? [];
        $_COOKIE = $_COOKIE ?? [];
        
        // Clear any remaining output buffers
        while (ob_get_level()) {
            ob_end_clean();
        }
    }
});