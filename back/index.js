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

    // 세션 유효성 검증
    const userSession = database.getUserSession(id);
    if (!userSession || !CheckSession(cookie, userSession.Cookie)) {
        res.status(401).json({
            ok: false,
            error: '유효하지 않은 세션입니다'
        });
        return;
    }

    // 도서관 로그아웃 요청
    request.get({
        url: 'https://lib.khu.ac.kr/logout',
        headers: {
            'User-Agent': 'request',
            Cookie: cookie
        }
    }, function(err, response, body) {
        if (err) {
            console.error('도서관 로그아웃 실패:', err);
            res.status(500).json({
                ok: false,
                error: '도서관 로그아웃 중 오류가 발생했습니다'
            });
            return;
        }

        // 세션 삭제
        database.logout(id, cookie, () => {
            res.json({
                ok: true,
                message: '로그아웃 성공'
            });
        }, (err) => {
            res.status(500).json({
                ok: false,
                error: err
            });
        });
    });
});
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

app.get('/complain/:stationId/passedby', (req, res) => {
    const stationId = req.params.stationId;
    const predictions = database.getStoredPredictionsByStation(stationId);
    
    if (!predictions || predictions.length === 0) {
        res.status(404).json({
            ok: false,
            message: "저장된 값이 없습니다"
        });
        return;
    }

    res.json({
        ok: true,
        data: predictions
    });
});

app.get('/bus/history', async (req, res) => {
    try {
        const { routeId, stationId, date } = req.query;
        
        // 필수 파라미터 검증
        if (!routeId || !stationId || !date) {
            return res.status(400).json({
                ok: false,
                error: '필수 파라미터가 누락되었습니다'
            });
        }
        const staOrder = database.getStaOrder(stationId, routeId);
        if (!staOrder) {
            return res.status(400).json({
                ok: false,
                error: '해당 정류장과 노선의 조합이 유효하지 않습니다'
            });
        }
        // 날짜 형식 검증 (YYYY-MM-DD)
        const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
        if (!dateRegex.test(date)) {
            return res.status(400).json({
                ok: false,
                error: '올바른 날짜 형식이 아닙니다 (YYYY-MM-DD)'
            });
        }

        const result = await database.getPastBusArrival(routeId, stationId, staOrder, date, false);
        res.json(result);

    } catch (error) {
        console.error('과거 버스 기록 조회 중 오류:', error);
        res.status(500).json({
            ok: false,
            error: '과거 버스 기록을 조회하는 중 오류가 발생했습니다'
        });
    }
});

app.get('/bus/history/byTime', async (req, res) => {
    try {
        const { stationId, date } = req.query;
        
        // 필수 파라미터 검증
        if (!stationId || !date) {
            return res.status(400).json({
                ok: false,
                error: '필수 파라미터가 누락되었습니다'
            });
        }
        // 날짜 형식 검증 (YYYY-MM-DD)
        const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
        if (!dateRegex.test(date)) {
            return res.status(400).json({
                ok: false,
                error: '올바른 날짜 형식이 아닙니다 (YYYY-MM-DD)'
            });
        }

        // 해당 정류장의 모든 버스 노선에 대한 기록 조회
        const stationRoutes = database.stationRouteOrder[stationId];
        if (!stationRoutes) {
            return res.status(400).json({
                ok: false,
                error: '해당 정류장의 노선 정보가 없습니다'
            });
        }

        let allResults = [];
        for (const [routeId, staOrder] of Object.entries(stationRoutes)) {
            if (database.busRouteMap[routeId]) {  // busRouteMap에 있는 노선만 처리
                const result = await database.getPastBusArrival(routeId, stationId, staOrder, date, true);  // true는 7일 전 데이터만 가져오는 플래그
                if (result.ok && result.data) {
                    allResults = allResults.concat(result.data);
                }
            }
        }

        // 시간순 정렬 (RArrivalDate 기준)
        allResults.sort((a, b) => {
            const timeA = new Date(a.RArrivalDate);
            const timeB = new Date(b.RArrivalDate);
            return timeA - timeB;
        });

        res.json({
            ok: true,
            data: allResults,
            stationName: database.stationMap[stationId],
            lastUpdate: new Date()
        });

    } catch (error) {
        console.error('과거 버스 기록 조회 중 오류:', error);
        res.status(500).json({
            ok: false,
            error: '과거 버스 기록을 조회하는 중 오류가 발생했습니다'
        });
    }
});


