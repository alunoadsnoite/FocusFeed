#!/usr/bin/env python3
"""Generate an ignored local release key. Never print or commit its password."""
from pathlib import Path
import os
import secrets
import subprocess

root = Path(__file__).resolve().parent.parent
private = root / '.private'
private.mkdir(mode=0o700, exist_ok=True)
properties = private / 'key.properties'
keystore = private / 'focusfeed-release.jks'
if properties.exists():
    print('Existing release signing configuration preserved.')
    raise SystemExit(0)
if keystore.exists():
    raise SystemExit('Existing keystore has no properties; restore its configuration instead of replacing it.')
password = secrets.token_urlsafe(36)
env = dict(os.environ, FOCUSFEED_STORE_PASSWORD=password)
subprocess.run(['keytool', '-genkeypair', '-keystore', str(keystore), '-storetype', 'JKS',
    '-alias', 'focusfeed', '-keyalg', 'RSA', '-keysize', '4096', '-validity', '10000',
    '-storepass:env', 'FOCUSFEED_STORE_PASSWORD', '-keypass:env', 'FOCUSFEED_STORE_PASSWORD',
    '-dname', 'CN=FocusFeed, O=FocusFeed'], env=env, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
properties.write_text('storeFile=../../.private/focusfeed-release.jks\nkeyAlias=focusfeed\nstorePassword='+password+'\nkeyPassword='+password+'\n')
os.chmod(properties, 0o600)
os.chmod(keystore, 0o600)
print('Release key generated locally; private material is excluded from Git.')
