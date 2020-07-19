#!/bin/bash
echo "## adding script in index.html ##"
sudo echo "<script>\$(function(){\$(\"img[src='']\").attr(\"src\", 'http://$(cat cloudfront_link.txt)');});</script>">> /var/www/html/index.html
echo "## index.html successfully updated ##"
echo "## restarting httpd service ##"
sudo systemctl restart httpd
echo "## httpd successfully restarted  ##"
echo "## exiting script... ##"
