@{
    SchemaVersion    = '1.0'
    MaxRecordAgeDays = 30

    # Phase 37 establishes the contract only. Future tool phases must add exact,
    # reviewed service names and mutation types before capture is permitted.
    ServiceScopes = @()

    # These core services stay denied unless a future migration explicitly
    # scopes the exact service and receives separate governance approval.
    ProtectedServiceNames = @(
        'BFE'
        'CryptSvc'
        'DcomLaunch'
        'EventLog'
        'LSM'
        'MpsSvc'
        'PlugPlay'
        'Power'
        'RpcEptMapper'
        'RpcSs'
        'SamSs'
        'Schedule'
        'TrustedInstaller'
        'WinDefend'
        'Winmgmt'
    )
}
