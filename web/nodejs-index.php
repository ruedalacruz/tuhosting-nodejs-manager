<?php
$TAB = "WEB";
include $_SERVER["DOCUMENT_ROOT"] . "/inc/main.php";

$tnm_user = (isset($_SESSION["look"]) && $_SESSION["look"] !== "" && ($_SESSION["userContext"] ?? "") === "admin") ? $_SESSION["look"] : $_SESSION["user"];
$tnm_helper = "/usr/bin/sudo /usr/local/sbin/tnmctl ";
$tnm_notice = null;
$tnm_result = null;
$selected = (string)($_GET["domain"] ?? $_POST["domain"] ?? "");

function tnm_call($user, $action, $domain = "", $slug = "", $extra = []) {
    global $tnm_helper;
    $cmd = $tnm_helper . escapeshellarg($user) . " " . escapeshellarg($action);
    foreach (array_merge([$domain, $slug], $extra) as $arg) {
        if ($arg !== "") $cmd .= " " . escapeshellarg((string)$arg);
    }
    exec($cmd . " 2>&1", $out, $rc);
    $data = json_decode(implode("\n", $out), true);
    return is_array($data) ? $data : ["ok" => false, "error" => "Respuesta inválida del administrador."];
}

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    verify_csrf($_POST, true);
    $action = (string)($_POST["action"] ?? "");
    $domain = (string)($_POST["domain"] ?? "");
    $slug = (string)($_POST["slug"] ?? "");
    $allowed = ["create", "update", "delete", "start", "stop", "restart", "logs", "npm-install"];
    if (!in_array($action, $allowed, true) || !preg_match('/^(?=.{1,253}$)[a-zA-Z0-9.-]+$/', $domain)) {
        $tnm_notice = ["ok" => false, "error" => "Solicitud inválida."];
    } else {
        $extra = [];
        if ($action === "create") {
            $extra = ["--name", (string)($_POST["name"] ?? ""), "--route", (string)($_POST["route"] ?? "/"), "--version", (string)($_POST["version"] ?? "24"), "--entry", (string)($_POST["entry"] ?? "server.js")];
        } elseif ($action === "update") {
            $extra = ["--name", (string)($_POST["name"] ?? ""), "--route", (string)($_POST["route"] ?? "/"), "--version", (string)($_POST["version"] ?? "24"), "--entry", (string)($_POST["entry"] ?? "server.js")];
        }
        $tnm_result = tnm_call($tnm_user, $action, $domain, $slug, $extra);
        $tnm_notice = $tnm_result;
        $selected = $domain;
    }
}

$cmd = HESTIA_CMD . "v-list-web-domains " . escapeshellarg($tnm_user) . " json 2>&1";
exec($cmd, $out, $rc);
$domains = $rc === 0 ? (json_decode(implode("\n", $out), true) ?: []) : [];
$tnm_versions = tnm_call($tnm_user, "versions");
$tnm_apps = [];
if ($selected !== "" && array_key_exists($selected, $domains)) $tnm_apps = tnm_call($tnm_user, "list", $selected);
else $selected = "";
render_page($user, $TAB, "nodejs");
