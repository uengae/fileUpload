<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oreilly.servlet.*" %>
<%@ page import="com.oreilly.servlet.multipart.*" %>
<%@ page import = "vo.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.sql.*" %>
<%@ page import = "java.util.*" %>
<%
	String dir = request.getServletContext().getRealPath("/upload");
	int maxFileSize = 1024 * 1024 * 10; // 10Mbyte
	// request 객체를 MultipartRequest의 API를 사용할 수 있도록 랩핑
	MultipartRequest mRequest = new MultipartRequest(request, dir, maxFileSize, "utf-8", new DefaultFileRenamePolicy());
	
	// MultipartRequest API를 사용하여 스트림내에서 문자값을 반환받을 수 있다.
	
	// 업로드 파일이 pdf 파일이 아니면
	if (mRequest.getContentType("boardFile").equals("application/pdf") == false){
		// 이미 저장된 파일을 삭제
		System.out.println("pdf 파일이 아닙니다.");
		String saveFilename = mRequest.getFilesystemName("boardFile");
		File f = new File(dir + "\\" + saveFilename);
		if(f.exists()){
			f.delete();
		System.out.println(dir + "\\" + saveFilename + "파일삭제");
		}
		response.sendRedirect(request.getContextPath() + "/addBoard.jsp");
		return;
	}
	// input type="text" 값 반환 API --> board 테이블 저장
	String boardTitle = mRequest.getParameter("boardTitle");
	String memberId = mRequest.getParameter("memberId");
	
	System.out.println(boardTitle + " <--boardTitle");
	System.out.println(memberId + " <--memberId");
	
	Board board = new Board();
	board.setBoardTitle(boardTitle);
	board.setMemberId(memberId);
	
	// input type="file" 값(파일 메타 정보) 반환 API(원본파일이름, 저장된파일이름, 컨텐츠타입)
	// --> board_flie 테이블 저장
	// 파일(바이너리)은 이미 MultipartRequest 객체 생성시(request랩핑시, 9라인) 먼저 저장
	String type = mRequest.getContentType("boardFile");
	String originFilename = mRequest.getOriginalFileName("boardFile");
	String saveFilename = mRequest.getFilesystemName("boardFile");
	
	System.out.println(type + " <--type");
	System.out.println(originFilename + " <--originFilename");
	System.out.println(saveFilename + " <--saveFilename");
	
	BoardFile boardFile = new BoardFile();
	// boardFile.setBoardNo(boardNo);
	boardFile.setType(type);
	boardFile.setOriginFilename(originFilename);
	boardFile.setSaveFilename(saveFilename);
	
	String driver = "org.mariadb.jdbc.Driver";
	String dbUrl= "jdbc:mariadb://127.0.0.1:3306/fileUpload";
	String dbUser = "root";
	String dbPw = "java1234";
	Class.forName(driver);
	Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPw);
	
	String insertBoardSql = "INSERT INTO board(board_title, member_id, updatedate, createdate) VALUES(?, ?, NOW(), NOW())";
	//PreparedStatement.RETURN_GENERATED_KEYS : insert 하면서 들어간 key값을 호출할 수 이싿.
	PreparedStatement insertBoardStmt = conn.prepareStatement(insertBoardSql, PreparedStatement.RETURN_GENERATED_KEYS);
	insertBoardStmt.setString(1, boardTitle);
	insertBoardStmt.setString(2, memberId);
	insertBoardStmt.executeUpdate();
	
	// getGeneratedKeys() key값을 불러오는것
	ResultSet keyRs = insertBoardStmt.getGeneratedKeys();
	int boardNo = 0;
	if(keyRs.next()){
		boardNo = keyRs.getInt(1);
	}
	
	String insertBoardFileSql = "INSERT INTO board_file(board_no, origin_filename, save_filename, type, path, createdate) VALUES(?, ?, ?, ?,'upload', NOW())";
	PreparedStatement insertBoardFileStmt = conn.prepareStatement(insertBoardFileSql);
	insertBoardFileStmt.setInt(1, boardNo);
	insertBoardFileStmt.setString(2, originFilename);
	insertBoardFileStmt.setString(3, saveFilename);
	insertBoardFileStmt.setString(4, type);
	insertBoardFileStmt.executeUpdate(); // board_file 입력
	
	response.sendRedirect(request.getContextPath() + "/boardList.jsp");
	
%>