#!/usr/local/bin/php
<?php
error_reporting(E_ALL);
require_once(dirname(__FILE__).'/libs/aws/aws-autoloader.php');

use Aws\S3\S3Client;
use Aws\Common\Enum\Size;
use Aws\Common\Exception\MultipartUploadException;
use Aws\S3\Model\MultipartUpload\UploadBuilder;


/*
*
* Push-to-Amazon-S3 Backup Script v1
*
* Daily web server script to be run manually or
* via cron job to push all backup files to Amazon S3
* storage for archiving.
*
* Author:
# Phil Rae, https://github.com/iamphilrae
*
*/
class PushToS3 {

	private $BACKUP_DIRECTORY;
	private $LOG_FILE;
  private $CONFIG;

  private $aws_client;


	public function __construct() {

	  require_once(dirname(__FILE__).'/config/aws.php');
    $this->CONFIG = $AWS_CONFIG;

    $this->BACKUP_DIRECTORY = $this->CONFIG['backup_directory'];
		$this->LOG_FILE = dirname(__FILE__).'/../logs/push_to_s3.log';


		try {
  		$this->aws_client = S3Client::factory(array(
        'key'    => $this->CONFIG['aws_access_key'],
        'secret' => $this->CONFIG['aws_access_secret']
      ));

      echo "Connected to S3.\n";
    }

    catch(Exception $e) {
      $this->report_message("ERROR: Failed to connect to S3:", $e->getMessage());
      echo "ERROR: Failed to connect to S3:" . $e->getMessage() . "\n";
      return false;
    }
	}


	/**
	* Set up the message reporting facility
	*/
	protected function report_message($subject, $message=null, $status=false) {

		$timestamp = $this->timestamp_now();

		if(!file_exists($this->LOG_FILE)) {
       $fp = fopen($this->LOG_FILE,"w");
       fwrite($fp,"0");
       fclose($fp);
    }

		if(is_null($message))
  		error_log("\n[".$timestamp."] ".$subject, 3, $this->LOG_FILE);

    else
  		error_log("\n[".$timestamp."] ".$subject."\n".$message, 3, $this->LOG_FILE);
	}


	/**
	* Utility function to get the current timestamp
	*/
	protected function timestamp_now($offset=false) {
		$datetime = new Datetime(null, new DateTimeZone('UTC'));

		if($offset !== false) {
			$datetime->sub(new DateInterval($offset));
		}
		return $datetime->format('Y-m-d H:i:sP');
	}


  /**
  * Cycle through the backups directory, pushing all files to S3
  */
  public function push_backup_directory() {

    echo "Locating backups to transmit at: '" . $this->BACKUP_DIRECTORY . "'\n";
    $done_something = false;

    foreach (new DirectoryIterator($this->BACKUP_DIRECTORY) as $fileinfo) {

      if($fileinfo->isDot() || $fileinfo->isDir()) continue;

      $done_something = true;
      $filename = $fileinfo->getFilename();
      $upload_status = false;

      // Attempt to create the uploader
      $uploader = null;

      echo "\nPUSHING: '$filename'\n";

      try {
        $uploader = UploadBuilder::newInstance()
          ->setClient($this->aws_client)
          ->setSource($this->BACKUP_DIRECTORY.'/'.$filename)
          ->setBucket($this->CONFIG['aws_backup_bucket'])
          ->setKey($this->CONFIG['aws_backup_folder'].$this->CONFIG['server_account'].'/'.$filename)
          ->build();
      }

      catch(Exception $e) {
        $this->report_message("ERROR: Creating uploader for '$filename' to S3:", $e->getMessage());
        echo "ERROR: Creating uploader for '$filename' to S3:" . $e->getMessage() . "\n";
        return false;
      }


      // Try and upload the file. Abort on fail.
      try {
        $uploader->upload();
        $this->report_message("SUCCESS: Pushed to S3: '$filename'");
        echo "SUCCESS\n";
        $upload_status = true;
      }

      catch(Exception $e) {
        $uploader->abort();
        $this->report_message("ERROR: Pushing to S3: '$filename'", $e->getMessage());
        echo "ERROR: Pushing to S3: '$filename':" . $e->getMessage() . "\n";
        return false;
      }

      // If upload was successful, delete the original on the server
      if($upload_status) {
        unlink($this->BACKUP_DIRECTORY.'/'.$filename);
      }

    } // foreach ($dir as $fileinfo)

    if( !$done_something ) {
      $this->report_message("ERROR: No backups to push. Check the directory config: '" . $this->BACKUP_DIRECTORY . "'");
      echo "ERROR: No backups to push. Check the directory config: '" . $this->BACKUP_DIRECTORY . "'\n";
    }

    echo "\nDone.\n\n";
  } // public function push_backup_directory()

}


$backup_cycle = new PushToS3();
$backup_cycle->push_backup_directory();
