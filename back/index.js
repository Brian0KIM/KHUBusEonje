const express = require('express')
const app = express()
const cors = require('cors');                           //서버간 통신 모듈
app.use(cors())
const { DateTime } = require('luxon');

const bodyParser = require('body-parser')
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({extended: true}))  


const PORT = 8081
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});

const database = require('./database/index')            //데이터베이스 파일 경로


function CheckSession(s1, s2) {
    const r1 = String(s1)
    const r2 = s2[0];
    return r1 === r2
}

const request = require('request')
const xml2js = require('xml2js');
const parser = new xml2js.Parser({ explicitArray: false }); // 배열을 단순화하는 옵션

app.post('/user/login', (req, res) => {
    const id = req.body.id                         //로그인시 아이디
    const pw = req.body.pw                //로그인시 비밀번호

    database.login(id, pw, (data, cookie) => {
        database.setSession(data.id, cookie)

        //  login
        request.post({
            url: 'https://libseat.khu.ac.kr/login_library',
            followAllRedirects: false,
            form: {
                STD_ID: data.id
            },
            headers: {
                'User-Agent': 'request',
                Cookie: cookie
            }
        }, function(err, result, body) {
            if (err) {
                console.log('lib login err', err)
                res.status(400).json({
                    ok: false,
                    err: err
                })
                return
            }

            database.setSession2(data.id, result.headers['set-cookie'])

            res.json({
                ok: true,
                name: data.name,
                id: data.id,
                cookie: cookie
            })
        })
    },
    (err) => {
        res.status(400).json({
            ok: false,
            err: err
        })
    })
    
})

app.post('/user/logout', (req, res) => {
    const id = req.body.id
    const cookie = req.body.cookie

    database.logout(id, cookie, (data) => {
        res.json({
            ok: true
        })
    },
    (err) => {
        res.status(400).json({
            ok: false,
            err: err
        })
    })
})
app.post('/user/status', (req, res) => {                 // 유저 정보 확인
    const id = req.body.id
    if (!id) {
        res.json({
            ok: false,
            err: 'id is required'
        })
        return
    }

    const sessionRecv = req.body.session
    const session = database.getSession(id)

    if (!session || !CheckSession(sessionRecv, session)) {
        res.status(401).json({
            ok: false,
            err: 'incorrect Session'
        })
        return
    }

    const data = database.getSeatById(id)
    if(data.length !== 0) {    
        res.json({
            ok: true,
            ismy: true,
            data: data[0]
        })
        return
    }

    database.getUserInfo(database.getSession2(id), (data) => {
        res.json({
            ok: true,
            data: data
        })
    }, (err) => {
        res.status(404).json({
            ok: false,
            err: err
        })
    })
})



app.get('/busInfo', (req, res) => {
    const routeId = req.query.routeId || '233000031';
    const url = 'http://apis.data.go.kr/6410000/buslocationservice/getBusLocationList';
    const serviceKey = 'YijIcFf7g0uISm%2BdQdDk5pw7WfFbMyqPPo9So6Jyxck0kr1YMHzTPR52qiBspoKxwxho0fOwe%2FTk%2FvBw%2B0ynuQ%3D%3D';
    const queryParams = '?' + encodeURIComponent('serviceKey') + '=' + serviceKey
        + '&' + encodeURIComponent('routeId') + '=' + encodeURIComponent(routeId);

    request({
        url: url + queryParams,
        method: 'GET'
    }, function (error, response, body) {
        if (error) {
            console.error('Request error:', error);
            res.status(400).json({
                ok: false,
                error: error
            });
            return;
        }
        
        // XML을 JSON으로 변환
        parser.parseString(body, (err, result) => {
            if (err) {
                console.error('XML Parse error:', err);
                res.status(400).json({
                    ok: false,
                    error: 'XML 파싱 오류'
                });
                return;
            }

            try {
                // XML 응답 구조에 따라 필요한 데이터 추출
                const busLocationList = result.response.msgBody.busLocationList;
                
                res.json({
                    ok: true,
                    data: busLocationList
                });
            } catch (e) {
                console.error('Data processing error:', e);
                res.status(400).json({
                    ok: false,
                    error: '데이터 처리 오류',
                    rawData: result // 디버깅용 전체 데이터
                });
            }
        });
    });
});

