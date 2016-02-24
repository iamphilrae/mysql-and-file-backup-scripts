#!/usr/local/bin/php
<?php
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
	  
	  $this->BACKUP_DIRECTORY = dirname(__FILE__).'/../backups';
		$this->LOG_FILE = dirname(__FILE__).'/../logs/push_to_s3.log';
		$this->CONFIG = $AWS_CONFIG;
		
		try {
  		$this->aws_client = S3Client::factory(array(
        'key'    => $this->CONFIG['access_key'],
        'secret' => $this->CONFIG['access_secret']
      ));
    }
    
    catch(Exception $e) {      
      $this->report_message("ERROR: Failed to connect to S3:", $e->getMessage());
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
    
    foreach (new DirectoryIterator($this->BACKUP_DIRECTORY) as $fileinfo) {
      
      if($fileinfo->isDot()) continue;
    
      $filename = $fileinfo->getFilename();
      $upload_status = false;
 
      // Attempt to create the uploader
      $uploader = null;  
                
      try {
        $uploader = UploadBuilder::newInstance()
          ->setClient($this->aws_client)
          ->setSource($this->BACKUP_DIRECTORY.'/'.$filename)
          ->setBucket($this->CONFIG['backup_bucket'])
          ->setKey($this->CONFIG['backup_folder'].$this->CONFIG['server_account'].'/'.$filename)
          ->build();
      }
      
      catch(Exception $e) {  
        $this->report_message("ERROR: Creating uploader for '$filename' to S3:", $e->getMessage());
        return false;
      }
      
      
      // Try and upload the file. Abort on fail.
      try {
        $uploader->upload();
        $this->report_message("SUCCESS: Pushed to S3: '$filename'");
        $upload_status = true;
      } 
      
      catch(Exception $e) {
        $uploader->abort();
        $this->report_message("ERROR: Pushing to S3: '$filename'", $e->getMessage());
        return false;
      }
  
      // If upload was successful, delete the original on the server
      if($upload_status) {
        unlink($this->BACKUP_DIRECTORY.'/'.$filename);
      }
      
    } // foreach ($dir as $fileinfo)
    
  } // public function push_backup_directory()
  
}


$backup_cycle = new PushToS3();
$backup_cycle->push_backup_directory();