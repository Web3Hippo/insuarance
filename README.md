# 어린이보험 보장 비교

현대해상과 KB손해보험의 **기존안·수정안 4개 설계**를 나란히 비교하는 정적 웹페이지입니다. 웹사이트를 열면 별도 이동 없이 보장 비교표가 바로 표시됩니다.

[비교 페이지](https://web3hippo.github.io/insuarance/) · [비교표 이미지](assets/comparison.png)

> 위 웹사이트 주소는 GitHub Pages 배포 완료 후 사용할 수 있습니다.

![현대·KB 기존안과 수정안 비교](assets/comparison.png)

## 비교 기준

확인일: 2026년 10월 30일. 받은 가입제안서를 기준으로 작성했습니다.

| 항목 | 현대 기존 | 현대 수정 | KB 기존 | KB 수정 |
|---|---:|---:|---:|---:|
| 원본 안내 월보험료 | 33,700원 | 30,130원 | 32,481원 | 35,689원 |
| 배상책임 제외 비교액 | 33,700원 | 30,130원 | 29,344원 | 32,552원 |
| 일반암 | 1억원 | 5천만원 | 5천만원 | 1억원 |
| 유사암 | 2천만원 | 1천만원 | 1천만원 | 2천만원 |

- KB 두 안은 가족일상생활배상책임 월 3,137원을 제외하고 독감 담보는 유지한 기준입니다. 삭제 후 보험사 재산출액은 다를 수 있습니다.
- 현대의 일반 질병입원일당은 **1~30일 2만원**과 **1~180일 5만원**을 각각 표시했습니다.
- 수정안에서 변경된 항목은 붉은 글씨로 표시합니다. 페이지의 버튼을 누르면 담보별 월보험료를 볼 수 있습니다.
- 표의 금액은 가입금액입니다. 실제 지급액은 약관의 질병분류·지급률·횟수·병원 및 치료 조건에 따릅니다.

## 파일 구성

```text
index.html                 첫 화면에 표시되는 비교표
assets/comparison.png      비교표 이미지
scripts/sync-comparison.cjs 로컬 비교표에서 공개 파일 갱신
scripts/prepare-site.cjs    배포할 파일만 _site에 준비
.github/workflows/pages.yml GitHub Pages 배포
```

이 저장소에는 비교표 공개에 필요한 파일을 버전 관리합니다. 원본 설계서, 개인 진료정보, 협업 메모, 임시 추출 파일은 로컬에 보관하며 Git 추적 대상에서 제외합니다.

## 로컬에서 보기

`index.html`을 브라우저로 열면 됩니다. 설치할 라이브러리나 빌드 도구는 없습니다.

개인 작업 폴더에서 원본 비교표를 수정한 뒤에는 다음 명령으로 첫 화면과 이미지를 갱신합니다.

```powershell
node scripts/sync-comparison.cjs
```

입력 파일은 `신생아_보험_사례조사/15_현대_KB_기존_수정_보장비교표.html`과 같은 이름의 PNG입니다. 입력 파일은 Git에 포함하지 않으므로 저장소를 새로 복제한 환경에서는 `index.html`을 직접 수정할 수 있습니다.

## GitHub Pages 배포

GitHub CLI(`gh`)와 Git이 설치된 사용자 PowerShell에서 아래 명령을 실행하면, 로그인·커밋·푸시·Pages 설정을 이어서 진행합니다. 원격 저장소가 이미 있어야 하며, 강제 푸시는 하지 않습니다.

푸시 전에 원격 `main`을 가져와 병합합니다. GitHub에서 만든 초기 커밋과 로컬 이력이 독립적인 경우도 처리하며, `README.md`만 충돌하면 준비한 비교표 안내문을 유지합니다. 다른 충돌은 병합을 취소하고 중단합니다.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish.ps1
```

수동으로 설정할 경우:

1. 저장소 **Settings → Pages → Build and deployment → Source**에서 **GitHub Actions**를 선택합니다.
2. `main`에 푸시하거나 Actions의 **Deploy comparison page**를 수동 실행합니다.
3. 배포가 완료되면 `https://web3hippo.github.io/insuarance/`에서 비교표를 확인합니다.

배포 워크플로는 `index.html`과 `assets`만 사이트에 올립니다. 저장소 공개 여부·계정 요금제에 따라 Pages 사용 가능 여부가 다를 수 있습니다.

참고: [GitHub Pages 사용자 지정 워크플로 공식 안내](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)
