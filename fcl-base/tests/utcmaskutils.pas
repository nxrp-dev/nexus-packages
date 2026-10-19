unit utcMaskUtils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, obNXTestContext, obNXTestRegistry, obNXTestSuite, maskutils;

procedure RegisterutcMaskUtilsTests(ARegistry: TNXTestRegistry);

implementation

procedure TMaskUtils_Test1(AContext: TNXTestContext);
begin

  AContext.AssertTrue(('H1H357-K808K-44616-YK8720') = (FormatMaskText('!>cccccc\-ccccc\-ccccc\-cccccc;0;*', 'H1H357K808K44616YK8720')), 'Test1');
end;

procedure TMaskUtils_Test2(AContext: TNXTestContext);
begin

  AContext.AssertTrue(('555.   .   .   ') = (FormatMaskText('999.999.999.999', '555555')), 'Test2');
end;

procedure TMaskUtils_Test3(AContext: TNXTestContext);
begin

  AContext.AssertTrue(('555.   .   .   ') = (FormatMaskText('999.999.999.999;1;_', '555555')), 'Test3');
end;

procedure RegisterutcMaskUtilsTests(ARegistry: TNXTestRegistry);
var
  lSuite: TNXTestSuite;
begin
  lSuite := ARegistry.AddSuite('FCL.Text.TMaskUtilsTests');
  lSuite.AddTest('Test1', @TMaskUtils_Test1, 'text');
  lSuite.AddTest('Test2', @TMaskUtils_Test2, 'text');
  lSuite.AddTest('Test3', @TMaskUtils_Test3, 'text');
end;

end.
