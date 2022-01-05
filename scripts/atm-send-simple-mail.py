import smtplib
import os
import argparse
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.image import MIMEImage
from email.mime.application import MIMEApplication

print("""
A part of
      ___           ___           ___     
     /\  \         /\  \         /\__\    
    /::\  \        \:\  \       /::|  |   
   /:/\:\  \        \:\  \     /:|:|  |   
  /::\~\:\  \       /::\  \   /:/|:|__|__ 
 /:/\:\ \:\__\     /:/\:\__\ /:/ |::::\__\\
 \/__\:\/:/  /    /:/  \/__/ \/__/~~/:/  /
      \::/  /    /:/  /            /:/  / 
      /:/  /     \/__/            /:/  /  
     /:/  /                      /:/  /   
     \/__/                       \/__/    

scripts by @9oelm https://github.com/9oelM

atm-send-simple-mail.py
""")
parser = argparse.ArgumentParser(description='send a single mail', add_help=False)
required = parser.add_argument_group('required arguments')
optional = parser.add_argument_group('optional arguments')
# Add back help 
optional.add_argument(
    '-h',
    '--help',
    action='help',
    default=argparse.SUPPRESS,
    help='show this help message and exit'
)
optional.add_argument("--content-subtype", "-cs", help="content (sub) type of the email. should be text/*. for example, \"plain\".", required=False, type=str, default="html")
optional.add_argument("--encoding", "-e", help="encoding of the email.", required=False, type=str, default="utf-8")
optional.add_argument("--title", "-t", help="title of the email.", required=False, type=str, default="test")
optional.add_argument("--mime", "-m", help="mime type of the email.", required=False, type=str, default="text")
required.add_argument("--email-from", "-ef", help="email address to send an email from", required=True, type=str)
required.add_argument("--email-from-pw", "-efp", help="password of the email account", required=True, type=str)
required.add_argument("--email-to", "-et", help="email address to send an email to", required=True, type=str)
required.add_argument("--payload", "-p", help="content of the mail", required=True, type=str)
args = parser.parse_args()

smtp_info = {
  "smtp_server" : "smtp.gmail.com",
  "smtp_user_id" : args.email_from,
  "smtp_user_pw" : args.email_from_pw,
  "smtp_port" : 587
}

class Mailer:
  def __init__(self, smtp_info):
    self.smtp_info = smtp_info

  def send_email(self, msg):
      with smtplib.SMTP(self.smtp_info["smtp_server"], self.smtp_info["smtp_port"], None, 3 * 60) as server:
          server.starttls() 
          server.login(self.smtp_info["smtp_user_id"], self.smtp_info["smtp_user_pw"])
          print(msg)
          response = server.sendmail(msg['from'], msg['to'], msg.as_string())

          if not response:
              print('Successfully sent')
          else:
              print(response)

  def insertInfoAndSendMail(self, title, toEmail, emailDate):
    if self.smtp_info["smtp_user_id"] == None or self.smtp_info["smtp_user_pw"] == None:
      print("Please set your email info")
      return

    multi = MIMEMultipart(_subtype='mixed')
    multi['Subject'] = title
    multi['From'] = self.smtp_info["smtp_user_id"]
    multi['To'] = toEmail
    multi['Date'] = emailDate

    if args.mime == "text":
        multi.attach(MIMEText(_text = args.payload, _charset = args.encoding, _subtype = args.content_subtype))
    elif args.mime == "image":
        multi.attach(MIMEImage(args.payload, _charset = args.encoding, _subtype = args.content_subtype))
    elif args.mime == "application":
        multi.attach(MIMEApplication(args.payload, _charset = args.encoding, _subtype = args.content_subtype))
    else:
        print(f'invalid mime type: ${args.mime}')
    self.send_email(multi)

mailer = Mailer(smtp_info)
mailer.insertInfoAndSendMail(
  args.title,
  args.email_to,
  "Fri, 0 Jul 9999 08:33:57 +0900",
)
