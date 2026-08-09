# MultiSig Wallet — Foundry Test Suite

Daha önce Hardhat ile geliştirdiğim MultiSig Wallet kontratının, **Foundry** kullanılarak ileri seviye test tekniklerine (fuzz testing, invariant testing) tabi tutulmuş hali. Amaç sadece kontratı test etmek değil, **Solidity-native bir test altyapısını** uçtan uca kurmak ve kontratın rastgele/beklenmedik senaryolar karşısında ne kadar sağlam olduğunu kanıtlamak.

## Neden Foundry?

Hardhat'te testler JavaScript ile yazılır. Foundry'de ise testler **doğrudan Solidity ile** yazılır — bu hem daha hızlı çalışır (Rust tabanlı) hem de kontratın iç mantığına çok daha yakın, güçlü test teknikleri (fuzzing, invariant testing) sunar.

## Test katmanları

Bu projede üç farklı seviyede test yazıldı:

### 1. Birim testleri (Unit tests)
Belirli, sabit senaryoları doğrulayan klasik testler — owner listesinin doğru kaydedildiği, gereken onay sayısının doğru ayarlandığı gibi temel kontroller.

### 2. Fuzz testleri
Tek bir fonksiyonu **yüzlerce farklı rastgele girdiyle** otomatik test eden yöntem. Bu projede:
- Deploy sırasında geçersiz onay sayılarının her zaman reddedildiği (`testFuzz_DeploymentRevertsWithInvalidConfirmations`)
- Geçerli onay sayılarının her zaman kabul edildiği (`testFuzz_DeploymentSucceedsWithValidConfirmations`)
- Rastgele adres ve miktarlarla önerilen işlemlerin doğru kaydedildiği (`testFuzz_SubmitTransaction`)
- Hangi owner onaylarsa onaylasın onay mekanizmasının tutarlı çalıştığı (`testFuzz_ConfirmTransactionIncreasesCount`)
- Her miktarda (1 wei'den 10 ETH'ye kadar) `executeTransaction`'ın alıcıya doğru tutarı gönderdiği (`testFuzz_ExecuteTransactionTransfersCorrectAmount`)

test edildi.

### 3. Invariant testleri
Foundry'nin en güçlü özelliği: kontratın **tüm fonksiyonlarını rastgele sırada, rastgele parametrelerle, art arda yüzlerce kez** çağırıp, belirlenen kuralların (invariant) **hiçbir koşulda bozulmadığını** doğrulamak. Bunun için bir `Handler` kontratı yazıldı (`MultiSigWalletHandler.t.sol`) — bu, Foundry'nin rastgele çağrılarını anlamlı sınırlar içinde tutuyor (var olmayan işlem index'i, geçersiz owner gibi anlamsız denemeleri engelliyor).

Doğrulanan kurallar:
- **`invariant_ConfirmationsNeverExceedOwnerCount`** — hiçbir işlemin onay sayısı, owner sayısını (3) asla geçemez
- **`invariant_ExecutedTransactionsHaveEnoughConfirmations`** — çalıştırılmış (executed) her işlem, gerçekten yeterli onaya sahip olmalıdır

## Gas raporu

`forge test --gas-report` ile her fonksiyonun ortalama/minimum/maksimum gas tüketimi ölçüldü. `executeTransaction` gibi kritik fonksiyonların gas tüketiminin, gönderilen miktardan bağımsız olarak **tutarlı** kaldığı doğrulandı — öngörülebilir maliyet, iyi kontrat tasarımının bir işaretidir.

## Proje yapısı

```
multisig-foundry/
├── src/
│   └── MultiSigWallet.sol              # Kontrat
├── test/
│   ├── MultiSigWallet.t.sol            # Birim + fuzz testleri
│   ├── MultiSigWalletHandler.t.sol     # Invariant testleri için handler
│   └── MultiSigWalletInvariant.t.sol   # Invariant testleri
├── foundry.toml
└── README.md
```

## Çalıştırma

```bash
forge build              # Derleme
forge test                # Tüm testleri çalıştır
forge test -vv            # Detaylı çıktı ile
forge test --gas-report   # Gas raporuyla birlikte
forge test --match-contract MultiSigWalletInvariantTest -vv   # Sadece invariant testleri
```

## Kullanılan teknolojiler

- Solidity ^0.8.24
- Foundry (forge, forge-std)

## Not

Bu proje, orijinal `multisig-wallet` (Hardhat) projesindeki kontratın **birebir aynısını** kullanır — amaç kontratı yeniden yazmak değil, ona **daha güçlü bir test katmanı** eklemekti. Kontratın manuel test edilmiş ve MetaMask ile çalışan bir web arayüzüne sahip hali için orijinal Hardhat projesine bakılabilir.