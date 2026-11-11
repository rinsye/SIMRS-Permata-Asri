<?php
require_once __DIR__.'/includes/functions.php';$user=require_login();$id=(int)($_GET['id']??0);$q=db()->prepare('SELECT a.*,r.id registration_id FROM emr_attachments a JOIN registrations r ON r.id=a.registration_id WHERE a.id=?');$q->execute([$id]);$a=$q->fetch();if(!$a){http_response_code(404);exit('Dokumen tidak ditemukan.');}
if(!in_array($user['role_code'],['admin_simrs','rekammedis'],true))require_patient_registration($user,(int)$a['registration_id'],'history');
$path=__DIR__.'/private_uploads/'.$a['stored_name'];if(!is_file($path)){http_response_code(404);exit('Berkas tidak tersedia.');}
header('Content-Type: '.$a['mime_type']);header('Content-Disposition: inline; filename="'.str_replace('"','',basename($a['original_name'])).'"');header('X-Content-Type-Options: nosniff');readfile($path);
