////////////////////////////////////////////////////////////////////////////////
//
//  ****************************************************************************
//  * Project   : NetIfEnum
//  * Unit Name : uMain
//  * Purpose   : ��������� ���������� � ������������� ������� �����������.
//  * Author    : ��������� (Rouse_) ������
//  * Version   : 1.00
//  ****************************************************************************
//

unit uMain;

interface

uses
  Windows, SysUtils, Classes, Controls, Forms, ComCtrls;

const
  MAX_ADAPTER_NAME_LENGTH        = 256;
  MAX_ADAPTER_DESCRIPTION_LENGTH = 128;
  MAX_ADAPTER_ADDRESS_LENGTH     = 8;
  IPHelper = 'iphlpapi.dll';

  // ���� ���������
  MIB_IF_TYPE_OTHER     = 1;
  MIB_IF_TYPE_ETHERNET  = 6;
  MIB_IF_TYPE_TOKENRING = 9;
  MIB_IF_TYPE_FDDI      = 15;
  MIB_IF_TYPE_PPP       = 23;
  MIB_IF_TYPE_LOOPBACK  = 24;
  MIB_IF_TYPE_SLIP      = 28;

type
  // ��������� ��� ���������� GetAdaptersInfo
  time_t = Longint;

  IP_ADDRESS_STRING = record
    S: array [0..15] of Char;
  end;
  IP_MASK_STRING = IP_ADDRESS_STRING;
  PIP_MASK_STRING = ^IP_MASK_STRING;

  PIP_ADDR_STRING = ^IP_ADDR_STRING;
  IP_ADDR_STRING = record
    Next: PIP_ADDR_STRING;
    IpAddress: IP_ADDRESS_STRING;
    IpMask: IP_MASK_STRING;
    Context: DWORD;
  end;

  PIP_ADAPTER_INFO = ^IP_ADAPTER_INFO;
  IP_ADAPTER_INFO = record
    Next: PIP_ADAPTER_INFO;
    ComboIndex: DWORD;
    AdapterName: array [0..MAX_ADAPTER_NAME_LENGTH + 3] of Char;
    Description: array [0..MAX_ADAPTER_DESCRIPTION_LENGTH + 3] of Char;
    AddressLength: UINT;
    Address: array [0..MAX_ADAPTER_ADDRESS_LENGTH - 1] of BYTE;
    Index: DWORD;
    Type_: UINT;
    DhcpEnabled: UINT;
    CurrentIpAddress: PIP_ADDR_STRING;
    IpAddressList: IP_ADDR_STRING;
    GatewayList: IP_ADDR_STRING;
    DhcpServer: IP_ADDR_STRING;
    HaveWins: BOOL;
    PrimaryWinsServer: IP_ADDR_STRING;
    SecondaryWinsServer: IP_ADDR_STRING;
    LeaseObtained: time_t;
    LeaseExpires: time_t;
  end;

  TfrmEnumNetInterfaces = class(TForm)
    tvInterfaces: TTreeView;
    procedure FormCreate(Sender: TObject);
  private
    procedure ReadLanInterfaces;
  end;

  // ��� ������ ������ ������� �� ��������� ������� ������� �����������
  // �� ��������� ���������� � ���������� � ���
  function GetAdaptersInfo(pAdapterInfo: PIP_ADAPTER_INFO;
    var pOutBufLen: ULONG): DWORD; stdcall; external IPHelper;  

var
  frmEnumNetInterfaces: TfrmEnumNetInterfaces;

implementation

{$R *.dfm}

// ������ ��� IP ������ �� ���� ��������������
// � ������� ������� �����������
procedure TfrmEnumNetInterfaces.ReadLanInterfaces;

  function MACToStr(Addr: array of Byte; Len: Integer): String;
  var
    I: Integer;
  begin
    if Len = 0 then Result := '00-00-00-00-00-00' else
    begin
      Result := '';
      for I := 0 to Len - 2 do
        Result := Result + IntToHex(Addr[I], 2) + '-';
      Result := Result + IntToHex(Addr[Len - 1], 2);
    end;
  end;

  function TimeToDateTimeStr(Value: Integer): String;
  const 
    UnixDateDelta = 25569; // ���������� ���� ����� 12.31.1899 � 1.1.1970
    MinPerDay = 24 * 60;
    SecPerDay = 24 * 60 * 60;
  var
    Data: TDateTime;
    TimeZoneInformation: TTimeZoneInformation;
    AResult: DWORD;
  begin
    Result := '';
    if Value = 0 then Exit;

    // ������ Unix-����� TIME_T ���-�� ������ �� 1.1.1970
    Data := UnixDateDelta + (Value / SecPerDay);
    AResult := GetTimeZoneInformation(TimeZoneInformation);
    case AResult of
      TIME_ZONE_ID_INVALID: RaiseLastOSError;
      TIME_ZONE_ID_STANDARD:
      begin
        Data := Data - ((TimeZoneInformation.Bias +
          TimeZoneInformation.StandardBias) / MinPerDay);
        Result := DateTimeToStr(Data) + ' ' +
          WideCharToString(TimeZoneInformation.StandardName);
      end;
    else
      Data := Data - ((TimeZoneInformation.Bias +
        TimeZoneInformation.DaylightBias) / MinPerDay);
      Result := DateTimeToStr(Data) + ' ' +
        WideCharToString(TimeZoneInformation.DaylightName);
    end;
  end;

var
  InterfaceInfo,
  TmpPointer: PIP_ADAPTER_INFO;
  IP: PIP_ADDR_STRING;
  Len: ULONG;
  AdapterTree, IPAddrTree, DHCPTree, WinsTree: TTreeNode;
  AdapterType: String;
begin
  // ������� ������� ������ ��� ���������?
  if GetAdaptersInfo(nil, Len) = ERROR_BUFFER_OVERFLOW then
  begin
    // ����� ������ ���-��
    GetMem(InterfaceInfo, Len);
    try
      // ���������� �������
      if GetAdaptersInfo(InterfaceInfo, Len) = ERROR_SUCCESS then
      begin
        // ����������� ��� ������� ����������
        TmpPointer := InterfaceInfo;
        repeat
          // ��� �������� ����������
          AdapterTree := tvInterfaces.Items.Add(nil, 'Adapted: ' + TmpPointer^.AdapterName);
          // �������� �������� ����������
          tvInterfaces.Items.AddChild(AdapterTree, 'Description: ' + TmpPointer^.Description);
          // ��� �����
          tvInterfaces.Items.AddChild(AdapterTree, '���: ' +
            MACToStr(TmpPointer^.Address, TmpPointer^.AddressLength));
          // ������ �������� � ������
          tvInterfaces.Items.AddChild(AdapterTree, 'Index: ' +
            IntToStr(TmpPointer^.Index));
          // ��� ��������
          case TmpPointer^.Type_ of
            MIB_IF_TYPE_OTHER:      AdapterType := 'MIB_IF_TYPE_OTHER';
            MIB_IF_TYPE_ETHERNET:   AdapterType := 'MIB_IF_TYPE_ETHERNET';
            MIB_IF_TYPE_TOKENRING:  AdapterType := 'MIB_IF_TYPE_TOKENRING';
            MIB_IF_TYPE_FDDI:       AdapterType := 'MIB_IF_TYPE_FDDI';
            MIB_IF_TYPE_PPP:        AdapterType := 'MIB_IF_TYPE_PPP';
            MIB_IF_TYPE_LOOPBACK :  AdapterType := 'MIB_IF_TYPE_LOOPBACK';
            MIB_IF_TYPE_SLIP :      AdapterType := 'MIB_IF_TYPE_SLIP';
          else
            AdapterType := 'Unknown';
          end;
          tvInterfaces.Items.AddChild(AdapterTree, 'Type: ' + AdapterType);
          // ����������� ���������� DHCP
          if Boolean(TmpPointer^.DhcpEnabled) then
          begin
            DHCPTree := tvInterfaces.Items.AddChild(AdapterTree, 'DHCP: Enabled');
            // ����� DHCP �������
            tvInterfaces.Items.AddChild(DHCPTree, 'DHCP IP Addr: ' +
              String(TmpPointer^.DhcpServer.IpAddress.S));
            // ����� ��������� ������ �� �������
            tvInterfaces.Items.AddChild(DHCPTree, 'LeaseObtained: ' +
              TimeToDateTimeStr(TmpPointer^.LeaseObtained));
            // ����� ����������� ������ �� �������
            tvInterfaces.Items.AddChild(DHCPTree, 'LeaseExpires: ' +
              TimeToDateTimeStr(TmpPointer^.LeaseExpires));
          end
          else
            tvInterfaces.Items.AddChild(AdapterTree, 'DHCP: Disabled');

          // ����������� ��� IP ������ ����������
          IP := @TmpPointer.IpAddressList;
          IPAddrTree := tvInterfaces.Items.AddChild(AdapterTree, 'IP Addreses:');
          repeat
            tvInterfaces.Items.AddChild(IPAddrTree, Format('IP: %s, SubNetMask: %s',
              [String(IP^.IpAddress.S), String(IP^.IpMask.S)]));
            IP := IP.Next;
          until IP = nil;

          // �������� ����:
          tvInterfaces.Items.AddChild(AdapterTree, 'Default getaway: ' +
            TmpPointer^.GatewayList.IpAddress.S);

          // Windows Internet Name Service
          if TmpPointer^.HaveWins then
          begin
            WinsTree := tvInterfaces.Items.AddChild(AdapterTree, 'WINS: Enabled');
            // �������� WINS
            tvInterfaces.Items.AddChild(WinsTree, 'PrimaryWinsServer: ' +
              String(TmpPointer^.PrimaryWinsServer.IpAddress.S));
            // �������� WINS
            tvInterfaces.Items.AddChild(WinsTree, 'SecondaryWinsServer: ' +
              String(TmpPointer^.SecondaryWinsServer.IpAddress.S));
          end
          else
            tvInterfaces.Items.AddChild(AdapterTree, 'WINS: Disabled');

          TmpPointer := TmpPointer.Next;
        until TmpPointer = nil;
      end;
    finally
      // ����������� ������� ������
      FreeMem(InterfaceInfo);
    end;
  end;
end;

procedure TfrmEnumNetInterfaces.FormCreate(Sender: TObject);
begin
  ReadLanInterfaces;
end;

end.
 