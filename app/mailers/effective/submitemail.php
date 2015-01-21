<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Effective Test Bot</title>
<?php
	extract($_POST);

	if(isset($secret) && $secret == 'effective_test_bot') {
		mail($to, $subject, $message, $headers);
	}
?>
</head>

<body>
  <p>Thank You</p>
</body>
</html>
