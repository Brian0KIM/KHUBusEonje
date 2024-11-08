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
        const { routeId, stationId, staOrder, date } = req.query;
        
        // 필수 파라미터 검증
        if (!routeId || !stationId || !staOrder || !date) {
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
        const stationRoutes = stationRouteOrder[stationId];
        if (!stationRoutes) {
            return res.status(400).json({
                ok: false,
                error: '해당 정류장의 노선 정보가 없습니다'
            });
        }

        let allResults = [];
        for (const [routeId, staOrder] of Object.entries(stationRoutes)) {
            if (busRouteMap[routeId]) {  // busRouteMap에 있는 노선만 처리
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
            stationName: stationMap[stationId],
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



// staOrder 매핑 객체 추가
const stationRouteOrder = {
    "228001174":{//사색의광장(정문행)
        "200000103": "1",//9번 
        "200000115": "1",//5100
        "200000112": "1",//7000
        "234001243": "1",//M5107
        "234000884": "1",//1560A
        "234000016": "1",//1112
        "228000433": "1",//1560B
    },
    "228000704":{//생명과학대.산업대학(정문행)
        "200000103": "2",//9번 
        "200000115": "2",//5100
        "200000112": "2",//7000
        "234001243": "2",//M5107
        "234000884": "2",//1560A
        "234000016": "2",//1112
        "228000433": "2",//1560B
    },
    "228000703":{//경희대체육대학.외대(정문행)
        "200000103": "3",//9번 
        "200000115": "3",//5100
        "200000112": "3",//7000
        "234001243": "3",//M5107
        "234000884": "3",//1560A
        "234000016": "3",//1112
        "228000433": "3",//1560B
    },
    "203000125":{//경희대학교(정문행)
        "200000103": "4",//9번 
        "200000115": "4",//5100
        "200000112": "4",//7000
        "234001243": "4",//M5107
        "234000884": "4",//1560A
        "234000016": "4",//1112
        "228000433": "4",//1560B
    },
    "228000723":{//경희대정문(사색행)
        "200000103": "87",//9번 
        "200000115": "56",//5100
        "200000112": "76",//7000
        "234001243": "60",//M5107
        "234000884": "99",//1560A
        "234000016": "68",//1112
        "228000433": "99",//1560B
    },
    "228000710":{//외국어대학(사색행)
        "200000103": "88",//9번 
        "200000115": "57",//5100
        "200000112": "77",//7000
        "234001243": "61",//M5107
        "234000884": "100",//1560A
        "234000016": "69",//1112
        "228000433": "100",//1560B
    },
    "228000709":{//생명과학대(사색행)
        "200000103": "89",//9번 
        "200000115": "58",//5100
        "200000112": "78",//7000
        "234001243": "62",//M5107
        "234000884": "101",//1560A
        "234000016": "70",//1112
        "228000433": "101",//1560B
    },
    "228000708":{//사색의광장(사색행)
        "200000103": "90",//9번 
        "200000115": "59",//5100
        "200000112": "79",//7000
        "234001243": "63",//M5107
        "234000884": "102",//1560A
        "234000016": "71",//1112
        "228000433": "102",//1560B
    }
};