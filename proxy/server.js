const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const path = require('path');
const cors = require('cors');
const bodyParser = require('body-parser');
const app = express();

// 웹 빌드 경로 설정
const webBuildPath = path.join(__dirname, '../flutter_app/build/web');
console.log('웹 빌드 경로:', webBuildPath);

// JSON 요청 본문 파싱 설정
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// CORS 설정 추가
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// 로깅 미들웨어 
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} | ${req.method} ${req.url}`);
  next();
});

// Flutter 웹 앱 정적 파일 서빙 (API 프록시 전에 정적 파일 처리)
app.use(express.static(webBuildPath));

// 테스트 API 엔드포인트 추가
app.post('/test-api', (req, res) => {
  console.log('테스트 API 호출됨:', req.body);
  // 요청 본문에서 query와 collections를 추출
  const queryText = req.body.query?.query || 'No query provided';
  const collections = req.body.collections || ['test'];
  
  console.log('쿼리:', queryText);
  console.log('컬렉션:', collections);
  
  res.json({
    answer: '테스트 응답이 성공적으로 반환되었습니다! 쿼리: ' + queryText,
    collections_used: collections,
    error: ''
  });
});

// // /chat 엔드포인트를 위한 프록시 설정
// app.use('/chat', createProxyMiddleware({ 
//   target: 'http://localhost:8095',
//   changeOrigin: true,
//   pathRewrite: { '^/chat': '/chat' }, // /chat 경로 유지
//   onProxyReq: (proxyReq, req, res) => {
//     // 요청 바디 로깅
//     if (req.body) {
//       console.log('요청 본문:', JSON.stringify(req.body, null, 2));
      
//       // 요청 세부 정보 로깅
//       console.log('요청 URL:', req.url);
//       console.log('타겟 URL:', `${proxyReq.protocol}//${proxyReq.host}${proxyReq.path}`);
//       console.log('Content-Type:', req.headers['content-type']);
      
//       // Content-Type 헤더에 charset=utf-8 추가
//       if (req.headers['content-type'] && !req.headers['content-type'].includes('charset=utf-8')) {
//         proxyReq.setHeader('Content-Type', 'application/json; charset=utf-8');
//         console.log('Content-Type 헤더 수정: application/json; charset=utf-8');
//       }
//     }
//   },
//   onProxyRes: (proxyRes, req, res) => {
//     // 응답 헤더 설정
//     proxyRes.headers['content-type'] = 'application/json; charset=utf-8';
    
//     // CORS 헤더 명시적 설정
//     proxyRes.headers['Access-Control-Allow-Origin'] = '*';
//     proxyRes.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
//     proxyRes.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization';
    
//     // 오류 디버깅을 위한 응답 내용 로깅
//     let responseBody = '';
//     const originalWrite = res.write;
//     const originalEnd = res.end;
    
//     // 응답 데이터 수집
//     proxyRes.on('data', (chunk) => {
//       responseBody += chunk.toString('utf8');
//     });
    
//     // 응답 완료 시 로깅
//     proxyRes.on('end', () => {
//       try {
//         // 응답이 JSON인지 확인
//         if (proxyRes.headers['content-type']?.includes('application/json')) {
//           console.log('응답 데이터(원본):', responseBody);
//           // JSON 파싱 및 출력 시도 (디버깅용)
//           try {
//             const jsonResponse = JSON.parse(responseBody);
//             console.log('파싱된 JSON 응답:', JSON.stringify(jsonResponse, null, 2));
//           } catch (e) {
//             console.error('JSON 파싱 오류:', e);
//             console.log('응답 데이터 처리 불가');
//           }
//         }
//       } catch (e) {
//         console.error('응답 처리 중 오류:', e);
//       }
//     });
//   }
// }));

// // /api로 시작하는 모든 요청을 백엔드로 프록시
// app.use('/api', createProxyMiddleware({ 
//   target: 'http://localhost:8095',
//   changeOrigin: true,
//   pathRewrite: { '^/api': '/api' }, // /api 프리픽스 유지
//   onProxyReq: (proxyReq, req, res) => {
//     // 요청 경로 로깅
//     const originalPath = req.originalUrl;
//     console.log('원래 요청 경로:', originalPath);
//     console.log('변경된 요청 경로:', proxyReq.path);
    
//     // API 요청 및 경로 재작성 로깅
//     console.log(`프록시 요청: ${req.method} ${req.originalUrl} -> ${proxyReq.path}`);
//     console.log(`대상 URL: ${proxyReq.protocol}//${proxyReq.host}${proxyReq.path}`);
    
//     // Content-Type 헤더에 charset=utf-8 추가
//     if (req.headers['content-type'] && !req.headers['content-type'].includes('charset=utf-8')) {
//       proxyReq.setHeader('Content-Type', 'application/json; charset=utf-8');
//       console.log('Content-Type 헤더 수정: application/json; charset=utf-8');
//     }
    
//     // 요청 본문 데이터가 있는 경우 로깅
//     if (req.body) {
//       console.log('요청 본문:', JSON.stringify(req.body, null, 2));
      
//       // POST 요청에서 body가 비어있는 경우 다시 쓰기
//       if (req.method === 'POST') {
//         const bodyData = JSON.stringify(req.body);
//         // content-length 헤더를 요청 본문 크기로 설정
//         proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
//         // 요청 본문 쓰기
//         proxyReq.write(bodyData);
//         proxyReq.end();
//       }
//     }
//   },
//   onProxyRes: (proxyRes, req, res) => {
//     console.log(`프록시 응답: ${proxyRes.statusCode} (${req.url})`);
    
//     // 응답 헤더에 CORS 헤더 및 인코딩 추가
//     proxyRes.headers['content-type'] = 'application/json; charset=utf-8';
//     proxyRes.headers['Access-Control-Allow-Origin'] = '*';
//     proxyRes.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
//     proxyRes.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization';
    
//     // 디버깅: 응답 내용 로깅
//     let responseBody = '';
    
//     proxyRes.on('data', (chunk) => {
//       responseBody += chunk.toString('utf8');
//     });
    
//     proxyRes.on('end', () => {
//       try {
//         console.log(`응답 데이터(${req.url}):`, responseBody.substring(0, 200) + '...');
//       } catch (e) {
//         console.error('응답 로깅 중 오류:', e);
//       }
//     });
//   }
// }));

// 모든 요청을 index.html로 리디렉션하는 미들웨어
const indexHtmlMiddleware = (req, res, next) => {
  // API 요청이면 다음 미들웨어로 넘김
  if (req.url.startsWith('/chat') || req.url.startsWith('/api')) {
    return next();
  }
  
  // 정적 파일이 아닌 다른 모든 요청은 index.html로 서빙
  res.sendFile(path.join(webBuildPath, 'index.html'));
};

// index.html 미들웨어 적용 (API 프록시 이후에 적용)
app.use(indexHtmlMiddleware);

// 포트 설정 (명령줄 인자 또는 환경변수, 기본값은 8096)
const PORT = process.argv.includes('--port') 
  ? process.argv[process.argv.indexOf('--port') + 1] 
  : (process.env.PORT || 8096);

app.listen(PORT, () => {
  console.log(`프록시 서버가 포트 ${PORT}에서 실행 중입니다.`);
  console.log(`Flutter 웹 앱: http://localhost:${PORT}`);
  console.log(`API 요청은 http://localhost:8095으로 프록시됩니다.`);
});