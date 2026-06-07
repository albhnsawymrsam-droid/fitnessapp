import urllib.request
import urllib.error
urls = [
    'https://gp-backend-production-7b9a.up.railway.app/api/login',
    'https://gp-backend-production-7b9a.up.railway.app/login',
    'https://gp-backend-production-7b9a.up.railway.app/api/',
    'https://gp-backend-production-7b9a.up.railway.app/'
]
for u in urls:
    try:
        req = urllib.request.Request(u, method='GET')
        with urllib.request.urlopen(req, timeout=20) as r:
            print(u, '->', r.status, r.read(200))
    except urllib.error.HTTPError as e:
        print(u, 'HTTP', e.code, e.read(200))
    except Exception as e:
        print(u, 'ERR', e)
