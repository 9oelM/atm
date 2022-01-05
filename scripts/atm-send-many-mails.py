#!/bin/python3
import smtplib
import os
import argparse
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import List
from time import sleep

parser = argparse.ArgumentParser(description='send many mails, each with an interval', add_help=False)
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
required.add_argument("--email-from", "-ef", help="email address to send an email from", required=True, type=str)
required.add_argument("--email-from-pw", "-efp", help="password of the email account", required=True, type=str)
required.add_argument("--email-to", "-et", help="email address to send an email to", required=True, type=str)
required.add_argument("--payload-path", "-pp", help="payload text file path", required=True, type=str)
optional.add_argument("--send-interval", "-si", help="interval between each mail being sent", required=False, type=int, default=50)
optional.add_argument("--start-chunk", "-sc", help="nth chunk to start from", required=False, type=int, default=0)
args = parser.parse_args()

smtp_info = {
  "smtp_server" : "smtp.gmail.com",
  "smtp_user_id" : args.email_from,
  "smtp_user_pw" : args.email_from_pw,
  "smtp_port" : 587,
  "recipients": [
      args.email_to
  ],
  "date": "Fri, 0 Jul 9999 08:33:57 +0900",
  # prepended to the actual subject
  "subject": "test"
}

class Mailer:
  def __init__(self, smtp_info):
    self.smtp_info = smtp_info

  def send_email(self, msg: MIMEMultipart):
      with smtplib.SMTP(self.smtp_info["smtp_server"], self.smtp_info["smtp_port"], None, 3 * 60) as server:
          server.starttls() 
          server.login(self.smtp_info["smtp_user_id"], self.smtp_info["smtp_user_pw"])
          response = server.send_message(msg)

          if not response:
              print('Successfully sent')
          else:
              print(response)

  def insert_info_and_send_mail(self, subject, to_emails, email_date, xss_payload) -> None:
    if self.smtp_info["smtp_user_id"] == None or self.smtp_info["smtp_user_pw"] == None:
      print("Please set your email info")
      return

    print(subject, to_emails, email_date, xss_payload)
    multi = MIMEMultipart(_subtype='mixed')
    multi['Subject'] = ""
    multi['From'] = self.smtp_info["smtp_user_id"]
    multi['To'] = ','.join(to_emails)
    multi['Date'] = email_date
    multi['In-Reply-To'] = ""
    multi['References'] = ""
    multi.attach(MIMEText(_text = xss_payload, _charset = "utf-8", _subtype = "html"))
    self.send_email(multi)
  
  def read_payload_file_and_divide_lines_into_chunks(self, file_path: str, divide_up_to_lines: int) -> List[List[str]]:
    lines = []
    try:
      with open(file_path, encoding="utf-8") as f:
        lines = f.readlines()
    except:
      print("[!] Failed to read payload file")
      exit(1)
    
    divided_lines = []
    for index, line in enumerate(lines):
      if index == 0 or (index) % divide_up_to_lines == 0:
        divided_lines.append([])
      divided_lines[-1].append(line)

    return divided_lines      
  
  # use interval_in_secs to avoid sending too many emails at once
  def send_all_payload_chunks_with_interval(self, interval_in_secs: int, chunks: List[List[str]], start_from_chunk: int) -> None:
    chunks_to_enumerate = [] 
    if start_from_chunk is not None:
      chunks_to_enumerate = chunks[start_from_chunk:] if len(chunks) > start_from_chunk else chunks
    for index, chunk in enumerate(chunks_to_enumerate):
      print(f"[+] Sending chunk {index}")
      single_chunk_with_new_lines = ''.join(chunk)
      print(f"----------showing the first 10 of the chunk--------\n{single_chunk_with_new_lines[0:10]}")
      self.insert_info_and_send_mail(f"{self.smtp_info.get('subject')} #{index}", self.smtp_info.get("recipients"), self.smtp_info.get("date"), single_chunk_with_new_lines)

      if index == len(chunks) - 1:
        return

      for sec in range(interval_in_secs):
        print(f"[+] Sending next email in {interval_in_secs - sec} second(s)")
        sleep(1)

mailer = Mailer(smtp_info)
mailer.send_all_payload_chunks_with_interval(30, mailer.read_payload_file_and_divide_lines_into_chunks(args.payload_path, args.send_interval), args.start_chunk)
