local config = require 'config.server'
local logger = require 'modules.logger'

GlobalState.PVPEnabled = config.server.pvp

-- Comando para verificar a identidade
lib.addCommand('verificarid', {
    help = 'Verifica se um cidadão já possui identidade.',
    params = {
        {
            name = 'id',
            type = 'playerId',
            help = 'ID do cidadão a verificar.'
        },
    },
    restricted = 'job.police' -- Mude 'police' se o nome do trabalho for outro
}, function(source, args, raw)
    local targetId = tonumber(args.id)
    if not targetId then
        TriggerClientEvent('QBCore:Notify', source, 'ID do jogador inválido.', 'error')
        return
    end

    local targetPlayer = exports.qbx_core:GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Este cidadão não está na cidade.', 'error')
        return
    end

    -- Acessa os metadados do jogador para verificar a identidade
    local hasIdentity = targetPlayer.Functions.GetMetaData('has_identity')

    if hasIdentity then
        TriggerClientEvent('QBCore:Notify', source, 'O cidadão (ID: ' .. targetId .. ') JÁ POSSUI uma identidade registrada no sistema.', 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'O cidadão (ID: ' .. targetId .. ') consta como INDIGENTE. Ele nunca recebeu uma identidade.', 'error')
    end
end)

-- Comando para dar a identidade
lib.addCommand('daridentidade', {
    help = 'Conceder uma identidade a um cidadão.',
    params = {
        {
            name = 'id',
            type = 'playerId',
            help = 'ID do cidadão que receberá a identidade.'
        },
    },
    restricted = 'job.police' -- Mude 'police' se o nome do trabalho for outro
}, function(source, args, raw)
    local targetId = tonumber(args.id)
    if not targetId then
        TriggerClientEvent('QBCore:Notify', source, 'ID inválido.', 'error')
        return
    end

    local targetPlayer = exports.qbx_core:GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Cidadão não encontrado.', 'error')
        return
    end

    -- Verifica se a identidade já foi registrada antes de dar uma nova
    if targetPlayer.Functions.GetMetaData('has_identity') then
        TriggerClientEvent('QBCore:Notify', source, 'Este cidadão já possui uma identidade registrada!', 'error')
        return
    end

    -- Define o status 'has_identity' como verdadeiro nos metadados
    targetPlayer.Functions.SetMetaData('has_identity', true)

    -- Adiciona o item 'id_card' ao inventário do jogador alvo
    exports.ox_inventory:AddItem(targetPlayer.PlayerData.source, 'id_card', 1)

    -- Salva os dados do jogador para garantir que a mudança seja permanente
    targetPlayer.Functions.Save()

    TriggerClientEvent('QBCore:Notify', source, 'Você emitiu uma identidade para o cidadão com ID ' .. targetId .. '.', 'success')
    TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'Você recebeu sua carteira de identidade de um Policial Federal.', 'success')
end)

-- Restante dos comandos originais do qbx_core/server/commands.lua
lib.addCommand('tp', {
    help = locale('command.tp.help'),
    params = {
        { name = locale('command.tp.params.x.name'), help = locale('command.tp.params.x.help'), optional = false },
        { name = locale('command.tp.params.y.name'), help = locale('command.tp.params.y.help'), optional = true },
        { name = locale('command.tp.params.z.name'), help = locale('command.tp.params.z.help'), optional = true }
    },
    restricted = 'group.admin'
}, function(source, args)
    if args[locale('command.tp.params.x.name')] and not args[locale('command.tp.params.y.name')] and not args[locale('command.tp.params.z.name')] then
        local target = GetPlayerPed(tonumber(args[locale('command.tp.params.x.name')]) --[[@as number]])
        if target ~= 0 then
            local coords = GetEntityCoords(target)
            TriggerClientEvent('QBCore:Command:TeleportToPlayer', source, coords)
        else
            Notify(source, locale('error.not_online'), 'error')
        end
    else
        if args[locale('command.tp.params.x.name')] and args[locale('command.tp.params.y.name')] and args[locale('command.tp.params.z.name')] then
            local x = tonumber((args[locale('command.tp.params.x.name')]:gsub(',',''))) + .0
            local y = tonumber((args[locale('command.tp.params.y.name')]:gsub(',',''))) + .0
            local z = tonumber((args[locale('command.tp.params.z.name')]:gsub(',',''))) + .0
            if x ~= 0 and y ~= 0 and z ~= 0 then
                TriggerClientEvent('QBCore:Command:TeleportToCoords', source, x, y, z)
            else
                Notify(source, locale('error.wrong_format'), 'error')
            end
        else
            Notify(source, locale('error.missing_args'), 'error')
        end
    end
end)

lib.addCommand('tpm', {
    help = locale('command.tpm.help'),
    restricted = 'group.admin'
}, function(source)
    TriggerClientEvent('QBCore:Command:GoToMarker', source)
end)

lib.addCommand('togglepvp', {
    help = locale('command.togglepvp.help'),
    restricted = 'group.admin'
}, function()
    config.server.pvp = not config.server.pvp
    GlobalState.PVPEnabled = config.server.pvp
end)

lib.addCommand('addpermission', {
    help = locale('command.addpermission.help'),
    params = {
        { name = locale('command.addpermission.params.id.name'), help = locale('command.addpermission.params.id.help'), type = 'playerId' },
        { name = locale('command.addpermission.params.permission.name'), help = locale('command.addpermission.params.permission.help'), type = 'string' }
    },
    restricted = 'group.admin'
}, function(source, args)
    local player = GetPlayer(args[locale('command.addpermission.params.id.name')])
    local permission = args[locale('command.addpermission.params.permission.name')]
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    ---@diagnostic disable-next-line: deprecated
    AddPermission(player.PlayerData.source, permission)
end)

lib.addCommand('removepermission', {
    help = locale('command.removepermission.help'),
    params = {
        { name = locale('command.removepermission.params.id.name'), help = locale('command.removepermission.params.id.help'), type = 'playerId' },
        { name = locale('command.removepermission.params.permission.name'), help = locale('command.removepermission.params.permission.help'), type = 'string' }
    },
    restricted = 'group.admin'
}, function(source, args)
    local player = GetPlayer(args[locale('command.removepermission.params.id.name')])
    local permission = args[locale('command.removepermission.params.permission.name')]
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    ---@diagnostic disable-next-line: deprecated
    RemovePermission(player.PlayerData.source, permission)
end)

lib.addCommand('openserver', {
    help = locale('command.openserver.help'),
    restricted = 'group.admin'
}, function(source)
    if not config.server.closed then
        Notify(source, locale('error.server_already_open'), 'error')
        return
    end

    if IsPlayerAceAllowed(source, 'admin') then
        config.server.closed = false
        Notify(source, locale('success.server_opened'), 'success')
    else
        DropPlayer(source, locale('error.no_permission'))
    end
end)

lib.addCommand('closeserver', {
    help = locale('command.openserver.help'),
    params = {
        { name = locale('command.closeserver.params.reason.name'), help = locale('command.closeserver.params.reason.help'), type = 'string' }
    },
    restricted = 'group.admin'
}, function(source, args)
    if config.server.closed then
        Notify(source, locale('error.server_already_closed'), 'error')
        return
    end

    if IsPlayerAceAllowed(source, 'admin') then
        local reason = args[locale('command.closeserver.params.reason.name')] or 'No reason specified'
        config.server.closed = true
        config.server.closedReason = reason
        for k in pairs(QBX.Players) do
            if not IsPlayerAceAllowed(k --[[@as string]], config.server.whitelistPermission) then
                DropPlayer(k --[[@as string]], reason)
            end
        end

        Notify(source, locale('success.server_closed'), 'success')
    else
        DropPlayer(source, locale('error.no_permission'))
    end
end)

lib.addCommand('car', {
    help = locale('command.car.help'),
    params = {
        { name = locale('command.car.params.model.name'), help = locale('command.car.params.model.help') },
        { name = locale('command.car.params.keepCurrentVehicle.name'), help = locale('command.car.params.keepCurrentVehicle.help'), optional = true },
    },
    restricted = 'group.admin'
}, function(source, args)
    if not args then return end

    local ped = GetPlayerPed(source)
    local keepCurrentVehicle = args[locale('command.car.params.keepCurrentVehicle.name')]
    local currentVehicle = not keepCurrentVehicle and GetVehiclePedIsIn(ped, false)
    if currentVehicle and currentVehicle ~= 0 then
        DeleteVehicle(currentVehicle)
    end

    local _, vehicle = qbx.spawnVehicle({
        model = args[locale('command.car.params.model.name')],
        spawnSource = ped,
        warp = true,
    })

    local plate = qbx.getVehiclePlate(vehicle)
    config.giveVehicleKeys(source, plate, vehicle)
end)

lib.addCommand('dv', {
    help = locale('command.dv.help'),
    params = {
        { name = locale('command.dv.params.radius.name'), help = locale('command.dv.params.radius.help'), type = 'number', optional = true }
    },
    restricted = 'group.admin'
}, function(source, args)
    local ped = GetPlayerPed(source)
    local pedCars = {GetVehiclePedIsIn(ped, false)}
    local radius = args[locale('command.dv.params.radius.name')]

    local function isVehicleOwned(plate)
        local count = MySQL.scalar.await('SELECT count(*) from player_vehicles WHERE plate = ?', {plate})
        local update = MySQL.update.await("UPDATE player_vehicles SET state = ? WHERE plate = ? OR fakeplate = ?", {1, plate, plate})

        if count > 0 then
            if update > 0 then return true end
        end
        return true
    end

    if pedCars[1] == 0 or radius then -- Only execute when player is not in a vehicle or radius is explicitly defined
        pedCars = lib.callback.await('qbx_core:client:getVehiclesInRadius', source, radius)
    else
        pedCars[1] = NetworkGetNetworkIdFromEntity(pedCars[1])
    end

    if #pedCars ~= 0 then
        for i = 1, #pedCars do
            local pedCar = NetworkGetEntityFromNetworkId(pedCars[i])
            if pedCar and DoesEntityExist(pedCar) then
                DeleteVehicle(pedCar)
            end
        end
    end
end)

lib.addCommand('givemoney', {
    help = locale('command.givemoney.help'),
    params = {
        { name = locale('command.givemoney.params.id.name'), help = locale('command.givemoney.params.id.help'), type = 'playerId' },
        { name = locale('command.givemoney.params.moneytype.name'), help = locale('command.givemoney.params.moneytype.help'), type = 'string' },
        { name = locale('command.givemoney.params.amount.name'), help = locale('command.givemoney.params.amount.help'), type = 'number' }
    },
    restricted = 'group.admin'
}, function(source, args)
    local player = GetPlayer(args[locale('command.givemoney.params.id.name')])
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    player.Functions.AddMoney(args[locale('command.givemoney.params.moneytype.name')], args[locale('command.givemoney.params.amount.name')])
end)

lib.addCommand('setmoney', {
    help = locale('command.setmoney.help'),
    params = {
        { name = locale('command.setmoney.params.id.name'), help = locale('command.setmoney.params.id.help'), type = 'playerId' },
        { name = locale('command.setmoney.params.moneytype.name'), help = locale('command.setmoney.params.moneytype.help'), type = 'string' },
        { name = locale('command.setmoney.params.amount.name'), help = locale('command.setmoney.params.amount.help'), type = 'number' }
    },
    restricted = 'group.admin'
}, function(source, args)
    local player = GetPlayer(args[locale('command.setmoney.params.id.name')])
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    player.Functions.SetMoney(args[locale('command.setmoney.params.moneytype.name')], args[locale('command.setmoney.params.amount.name')])
end)

lib.addCommand('job', {
    help = locale('command.job.help')
}, function(source)
    local onduty = 'Não'
    local PlayerJob = GetPlayer(source).PlayerData.job
    if PlayerJob.onduty then onduty = 'Sim' end
    Notify(source, locale('info.job_info', PlayerJob?.label, PlayerJob?.grade.name, onduty))
end)

lib.addCommand('setjob', {
    help = locale('command.setjob.help'),
    params = {
        { name = locale('command.setjob.params.id.name'), help = locale('command.setjob.params.id.help'), type = 'playerId' },
        { name = locale('command.setjob.params.job.name'), help = locale('command.setjob.params.job.help'), type = 'string' },
        { name = locale('command.setjob.params.grade.name'), help = locale('command.setjob.params.grade.help'), type = 'number', optional = true }
    },
    restricted = 'group.admin'
}, function(source, args)
    local player = GetPlayer(args[locale('command.setjob.params.id.name')])
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    local success, errorResult = player.Functions.SetJob(args[locale('command.setjob.params.job.name')], args[locale('command.setjob.params.grade.name')] or 0)
    assert(success, json.encode(errorResult))
end)

lib.addCommand('changejob', {
    help = locale('command.changejob.help'),
    params = {
        { name = locale('command.changejob.params.id.name'), help = locale('command.changejob.params.id.help'), type = 'playerId' },
        { name = locale('command.changejob.params.job.name'), help = locale('command.changejob.params.job.help'), type = 'string' },
    },
    restricted = 'group.admin'
}, function(source, args)
    local player = GetPlayer(args[locale('command.changejob.params.id.name')])
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    local success, errorResult = SetPlayerPrimaryJob(player.PlayerData.citizenid, args[locale('command.changejob.params.job.name')])
    assert(success, json.encode(errorResult))
end)

lib.addCommand('addjob', {
    help = locale('command.addjob.help'),
    params = {
        { name = locale('command.addjob.params.id.name'), help = locale('command.addjob.params.id.help'), type = 'playerId' },
        { name = locale('command.addjob.params.job.name'), help = locale('command.addjob.params.job.help'), type = 'string' },
        { name = locale('command.addjob.params.grade.name'), help = locale('command.addjob.params.grade.help'), type = 'number', optional = true}
    },
    restricted = 'group.admin'
}, function(source, args)
    local player = GetPlayer(args[locale('command.addjob.params.id.name')])
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    local success, errorResult = AddPlayerToJob(player.PlayerData.citizenid, args[locale('command.addjob.params.job.name')], args[locale('command.addjob.params.grade.name')] or 0)
    assert(success, json.encode(errorResult))
end)

lib.addCommand('removejob', {
    help = locale('command.removejob.help'),
    params = {
        { name = locale('command.removejob.params.id.name'), help = locale('command.removejob.params.id.help'), type = 'playerId' },
        { name = locale('command.removejob.params.job.name'), help = locale('command.removejob.params.job.help'), type = 'string' }
    },
    restricted = 'group.admin'
}, function(source, args)
    local player = GetPlayer(args[locale('command.removejob.params.id.name')])
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    local success, errorResult = RemovePlayerFromJob(player.PlayerData.citizenid, args[locale('command.removejob.params.job.name')])
    assert(success, json.encode(errorResult))
end)

lib.addCommand('gang', {
    help = locale('command.gang.help')
}, function(source)
    local PlayerGang = GetPlayer(source).PlayerData.gang
    Notify(source, locale('info.gang_info', PlayerGang?.label, PlayerGang?.grade.name))
end)

lib.addCommand('setgang', {
    help = locale('command.setgang.help'),
    params = {
        { name = locale('command.setgang.params.id.name'), help = locale('command.setgang.params.id.help'), type = 'playerId' },
        { name = locale('command.setgang.params.gang.name'), help = locale('command.setgang.params.gang.help'), type = 'string' },
        { name = locale('command.setgang.params.grade.name'), help = locale('command.setgang.params.grade.help'), type = 'number', optional = true }
    },
    restricted = 'group.admin'
}, function(source, args)
    local player = GetPlayer(args[locale('command.setgang.params.id.name')])
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    local success, errorResult = player.Functions.SetGang(args[locale('command.setgang.params.gang.name')], args[locale('command.setgang.params.grade.name')] or 0)
    assert(success, json.encode(errorResult))
end)

lib.addCommand('ooc', {
    help = locale('command.ooc.help')
}, function(source, args)
    local message = table.concat(args, ' ')
    local players = GetPlayers()
    local player = GetPlayer(source)
    if not player then return end

    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    for _, v in pairs(players) do
        if v == source then
            exports.chat:addMessage(v --[[@as Source]], {
                color = { 0, 0, 255},
                multiline = true,
                args = {('OOC | %s'):format(GetPlayerName(source)), message}
            })
        elseif #(playerCoords - GetEntityCoords(GetPlayerPed(v))) < 20.0 then
            exports.chat:addMessage(v --[[@as Source]], {
                color = { 0, 0, 255},
                multiline = true,
                args = {('OOC | %s'):format(GetPlayerName(source)), message}
            })
        elseif IsPlayerAceAllowed(v --[[@as string]], 'admin') then
            if IsOptin(v --[[@as Source]]) then
                exports.chat:addMessage(v--[[@as Source]], {
                    color = { 0, 0, 255},
                    multiline = true,
                    args = {('Proximity OOC | %s'):format(GetPlayerName(source)), message}
                })
                logger.log({
                    source = 'qbx_core',
                    webhook  = 'ooc',
                    event = 'OOC',
                    color = 'white',
                    tags = config.logging.role,
                    message = ('**%s** (CitizenID: %s | ID: %s) **Message:** %s'):format(GetPlayerName(source), player.PlayerData.citizenid, source, message)
                })
            end
        end
    end
end)

lib.addCommand('me', {
    help = locale('command.me.help'),
    params = {
        { name = locale('command.me.params.message.name'), help = locale('command.me.params.message.help'), type = 'string' }
    }
}, function(source, args)
    args[1] = args[locale('command.me.params.message.name')]
    args[locale('command.me.params.message.name')] = nil
    if #args < 1 then Notify(source, locale('error.missing_args2'), 'error') return end
    local msg = table.concat(args, ' '):gsub('[~<].-[>~]', '')
    local playerState = Player(source).state
    playerState:set('me', msg, true)

    -- We have to reset the playerState since the state does not get replicated on StateBagHandler if the value is the same as the previous one --
    playerState:set('me', nil, true)
end)

lib.addCommand('id', {help = locale('info.check_id')}, function(source)
    Notify(source, 'ID: ' .. source)
end)

lib.addCommand('logout', {
    help = locale('info.logout_command_help'),
    restricted = 'group.admin',
}, Logout)

lib.addCommand('deletechar', {
    help = locale('info.deletechar_command_help'),
    restricted = 'group.admin',
    params = {
        { name = 'id', help = locale('info.deletechar_command_arg_player_id'), type = 'number' },
    }
}, function(source, args)
    local player = GetPlayer(args.id)
    if not player then return end

    local citizenId = player.PlayerData.citizenid
    ForceDeleteCharacter(citizenId)
    Notify(source, locale('success.character_deleted_citizenid', citizenId))
end)
lib.addCommand('abordar', {
    help = 'Abordar e verificar informações de um cidadão próximo.',
    restricted = 'job.police' -- Mude 'police' se o nome do trabalho for outro
}, function(source, args, raw)
    -- Pede ao cliente para encontrar o jogador mais próximo
    local targetId = lib.callback.await('qbx_core:client:getPlayerInFront', source)

    if not targetId or targetId == -1 then
        TriggerClientEvent('QBCore:Notify', source, 'Nenhum cidadão encontrado à sua frente.', 'error')
        return
    end

    local targetPlayer = exports.qbx_core:GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', source, 'Cidadão não encontrado ou inválido.', 'error')
        return
    end

    -- Coleta as informações do jogador alvo
    local citizenid = targetPlayer.PlayerData.citizenid
    local serverId = targetPlayer.PlayerData.source
    local hasIdentity = targetPlayer.Functions.GetMetaData('has_identity')
    local identityStatus = hasIdentity and "<span style='color:green;'>Possui Identidade</span>" or "<span style='color:red;'>Indigente (Sem Registro)</span>"

    -- Monta a mensagem para o policial
    local infoMessage = string.format(
        "Informações da Abordagem:" ..
        "ID na Cidade:" ..
        "CitizenID:" ..
        "Status:",
        serverId, citizenid, identityStatus
    )

    -- Envia as informações para o policial e aciona as animações
    TriggerClientEvent('QBCore:Notify', source, infoMessage, 'primary', 7000)
    TriggerClientEvent('qbx_core:client:playAbordagemAnimation', source, targetId)
end)