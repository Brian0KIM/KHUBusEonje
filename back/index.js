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
        database.setSession(data.id, data.name, cookie)

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
app.get('/user/status', (req, res) => {
    const id = req.query.id;  // id는 쿼리로 받고
    const cookie = req.headers.authorization;  // 쿠키는 헤더로 받음
    
    if (!id || !cookie) {
        res.status(400).json({
            ok: false,
            error: '필수 정보가 누락되었습니다'
        });
        return;
    }

    // 전체 세션 정보 조회
    const userSession = database.getUserSession(id);
    if (!userSession) {
        res.status(401).json({
            ok: false,
            error: '로그인 정보를 찾을 수 없습니다'
        });
        return;
    }

    // 쿠키 검증
    if (!CheckSession(cookie, userSession.Cookie)) {
        res.status(401).json({
            ok: false,
            error: '유효하지 않은 세션입니다'
        });
        return;
    }

    res.json({
        ok: true,
        data: {
            id: id,
            name: userSession.name,
            isLoggedIn: true,
            sessionValid: true
        }
    });
});




app.get('/bus/:routeId/eta', (req, res) => {
    const routeId = req.params.routeId || '233000031';  // busId -> routeId로 수정
    
    database.mybusinfo(routeId, 
        (data) => {
            res.json(data);
        },
        (error) => {
            res.status(400).json({
                ok: false,
                error: error
            });
        }
    );
});


app.get('/stop/:path/:stationId/eta', (req, res) => {
    const stationId = req.params.stationId;
    const path = req.params.path;  // 경로 구분용 (international/seoul 등)
    
    database.getBusArrival(stationId, 
        (data) => {
            res.json(data);
        },
        (error) => {
            res.status(400).json({
                ok: false,
                error: error
            });
        }
    );
});